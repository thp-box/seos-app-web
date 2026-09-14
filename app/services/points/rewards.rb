module Points
  class Rewards
    def self.rule!
      PointRuleVersion.current("engagement") || raise(Exchanges::Invalid, "Aucun barème de récompenses n’est encore publié.")
    end

    def self.level(user, rule, through_id: nil)
      scope = transfers(user)
      scope = scope.where("point_operations.id <= ?", through_id) if through_id
      count = scope.count
      count >= rule.configuration["gold_after"] ? "gold" : (count >= rule.configuration["silver_after"] ? "silver" : "bronze")
    end

    def self.transfers(user)
      PointOperation.committed.where(kind: "service_transfer").joins(:point_entries).where(point_entries: { point_account_id: PointAccount.where(user: user).select(:id) })
        .where.not(id: PointOperation.where(kind: "reversal").select(:reversed_operation_id))
    end

    def self.grant!(user:, amount:, key:, kind:, source:, rule:, reason:, defer: false)
      raise Exchanges::Invalid, "Le compte doit être actif et son e-mail confirmé." unless user.active? && user.confirmed?
      account = PointAccount.for!(user)
      return PointOperation.find_by!(idempotency_key: key) if PointOperation.exists?(idempotency_key: key)
      earned = PointEntry.joins(:point_operation).where(point_account: account, amount: 1.., point_operations: { kind: %w[welcome_reward achievement_reward chain_reward referral_reward cycle_reward], committed_at: Time.current.beginning_of_month.. }).sum(:amount)
      if kind == "chain_reward"
        chain_earned = PointEntry.joins(:point_operation).where(point_account: account, amount: 1.., point_operations: { kind: "chain_reward", committed_at: Time.current.beginning_of_month.. }).sum(:amount)
        raise Exchanges::Invalid, "Le plafond mensuel des chaînes est atteint." if chain_earned + amount > rule.configuration["chain_monthly_cap"]
      end
      if earned + amount > rule.configuration["monthly_cap"]
        return nil if defer
        raise Exchanges::Invalid, "Le plafond mensuel de récompenses est atteint."
      end
      Ledger.post!(debit: PointAccount.system!, credit: account, amount: amount, key: key, kind: kind, source: source, rule: rule, reason: reason)
    end

    def self.welcome!(user)
      user.with_lock do
        raise Exchanges::Invalid, "Confirmez votre e-mail et publiez votre profil pour terminer l’accueil." unless user.profile&.published?
        rule = rule!
        grant!(user: user, amount: rule.configuration["welcome"], key: "welcome:#{user.id}", kind: "welcome_reward", source: user, rule: rule, reason: "Quête d’accueil terminée")
      end
    end

    def self.sync!(user)
      return unless user.active? && user.confirmed? && PointRuleVersion.current("engagement")
      user.with_lock do
        rule = rule!
        user.listings.where(status: "published").where.not(published_at: nil).find_each do |listing|
          next unless listing.publicly_visible?
          source_rule = PointRuleVersion.current("engagement", at: listing.published_at)
          next unless source_rule
          grant!(user: user, amount: source_rule.configuration["listing"], key: "listing:#{listing.id}", kind: "achievement_reward", source: listing, rule: source_rule, reason: "Quête : annonce publiée", defer: true)
        end
        replies = ServiceRequest.where(requester: user, status: %w[accepted scheduled awaiting_confirmation completed]).where(created_at: rule.effective_at..)
        if replies.distinct.count(:provider_id) >= 3
          grant!(user: user, amount: rule.configuration["responses"], key: "responses:#{user.id}", kind: "achievement_reward", source: user, rule: rule, reason: "Quête : trois demandes acceptées par des membres distincts", defer: true)
        end
        Referral.valid_support.where(referrer: user, primary_referrer: true).where.not(qualified_at: nil).order(:qualified_at, :id).each do |referral|
          next unless referral.referred_user.active? && referral.referred_user.confirmed? && referral.referred_user.created_at <= 30.days.ago
          next unless (Referrals.partners(referral.referred_user) - Referral.where(referred_user: referral.referred_user).pluck(:referrer_id)).size >= 2
          key = referral.referral_link_id ? "referral:#{referral.id}" : "referral_quest:#{user.id}"
          grant!(user: user, amount: 15, key: key, kind: "referral_reward", source: referral, rule: rule, reason: "Quête de parrain principal qualifiée", defer: true)
        end
        cycles!(user, rule)
      end
    end

    def self.cycles!(user, current_rule)
      progresses = PointCycleProgress.where(user: user).order(:cycle_number).to_a
      consumed = progresses.flat_map(&:operation_ids)
      available = transfers(user).where.not(id: consumed).order(:id).to_a
      progress = progresses.last
      if progress && !progress.point_operation
        progress.update!(operation_ids: progress.operation_ids & transfers(user).pluck(:id))
        return unless complete_cycle!(user, progress)
      end
      available.each do |transfer|
        if !progress || progress.point_operation
          source_rule = PointRuleVersion.current("engagement", at: transfer.committed_at) || current_rule
          progress = PointCycleProgress.create!(user: user, point_rule_version: source_rule, cycle_number: (progress&.cycle_number || 0) + 1)
        end
        progress.update!(operation_ids: progress.operation_ids + [ transfer.id ])
        return unless complete_cycle!(user, progress)
      end
    end

    def self.complete_cycle!(user, progress)
      rule = progress.point_rule_version
      return true if progress.operation_ids.size < rule.configuration["cycle_size"]
      amount = rule.configuration["cycle"].fetch(level(user, rule, through_id: progress.operation_ids.last))
      operation = grant!(user: user, amount: amount, key: "cycle:#{user.id}:#{progress.cycle_number}", kind: "cycle_reward", source: progress, rule: rule, reason: "Série de #{rule.configuration['cycle_size']} échanges en Points Services", defer: true)
      return false unless operation
      progress.update!(point_operation: operation)
      true
    end

    def self.submit!(user:, kind:, evidence:)
      raise Exchanges::Invalid, "Choisissez une quête avec preuve." unless %w[written video share chain].include?(kind)
      user.with_lock do
        rule = rule!
        current_level = level(user, rule)
        period = %w[share chain].include?(kind) ? Time.current.strftime("%Y-%m") : "lifetime"
        amount = rule.configuration[kind]
        amount = amount.fetch(current_level) if amount.is_a?(Hash)
        if kind == "chain"
          # Reviewed bridge for phase 5: one capped claim per month, never a client-supplied amount.
          amount = [ amount, rule.configuration["chain_monthly_cap"] ].min
        end
        PointRewardClaim.create!(user: user, kind: kind, evidence: evidence, period_key: period, point_rule_version: rule, level: current_level, amount: amount)
      end
    end

    def self.review!(claim, actor:, decision:, reason:)
      raise Pundit::NotAuthorizedError unless actor.permission?("points.rewards") && actor.id != claim.user_id
      raise Exchanges::Invalid, "Choisissez approuver ou refuser avec un motif." unless %w[approved rejected].include?(decision) && reason.present? && reason.size <= 500
      claim.user.with_lock do
        claim.reload
        return claim if claim.status == "approved" && decision == "approved"
        raise Exchanges::Invalid, "Cette preuve a déjà été examinée." unless claim.status == "pending"
        if decision == "approved"
          operation = grant!(user: claim.user, amount: claim.amount, key: "claim:#{claim.kind}:#{claim.user_id}:#{claim.period_key}", kind: claim.kind == "chain" ? "chain_reward" : "achievement_reward", source: claim, rule: claim.point_rule_version, reason: "Quête validée : #{claim.kind}")
        end
        claim.update!(status: decision, decision: reason, reviewed_by: actor, point_operation: operation)
        AuditLog.create!(actor: actor, target: claim, action: "points.reward.#{decision}", reason: reason)
        Notification.notify!(user: claim.user, key: "points:claim:#{claim.id}:#{decision}", title: "Votre preuve de quête a été examinée. La décision est disponible dans votre portefeuille.")
        claim
      end
    end
  end
end
