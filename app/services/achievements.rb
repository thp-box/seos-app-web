class Achievements
  def self.progress(user, achievement)
    case achievement.event_name
    when "welcome" then PointOperation.exists?(idempotency_key: "welcome:#{user.id}") ? 1 : 0
    when "listing" then user.listings.where(status: "published").count
    when "responses" then ServiceRequest.where(requester: user, status: %w[accepted scheduled awaiting_confirmation completed]).distinct.count(:provider_id)
    when "referral" then PointEntry.joins(:point_operation).where(point_account: PointAccount.where(user: user), point_operations: { kind: "referral_reward", status: "committed" }).exists? ? 1 : 0
    when "cycle" then Points::Rewards.transfers(user).count
    when "written", "video", "share"
      scope = PointRewardClaim.where(user: user, kind: achievement.event_name, status: "approved")
      scope = scope.where(period_key: Time.current.strftime("%Y-%m")) if achievement.recurrence == "monthly"
      scope.count
    when "chain" then ChainService.where(beneficiary: user, status: "confirmed").count
    else
      scope = UserAchievement.where(user: user, achievement: achievement, status: "approved")
      scope = scope.where(period_key: Time.current.strftime("%Y-%m")) if achievement.recurrence == "monthly"
      scope.count
    end
  end

  def self.submit!(user:, achievement:, evidence:, proof: nil)
    Chains.active!(user)
    raise Exchanges::Invalid, "Cette quête n’accepte pas de preuve personnalisée." unless achievement.active? && achievement.event_name == "manual"
    user.with_lock do
      rule = Points::Rewards.rule!
      amount = rule.configuration.fetch(achievement.reward_key)
      amount = amount.fetch(Points::Rewards.level(user, rule)) if amount.is_a?(Hash)
      record = UserAchievement.create!(user: user, achievement: achievement, point_rule_version: rule, points: amount,
        period_key: achievement.recurrence == "monthly" ? Time.current.strftime("%Y-%m") : "lifetime", evidence: evidence)
      SafeImage.attach!(record.proof, proof) if proof.present?
      record
    end
  end

  def self.review!(record:, actor:, decision:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("community.manage") && actor.id != record.user_id
    raise Exchanges::Invalid, "Décision ou motif invalide." unless %w[approved rejected reexamine].include?(decision) && reason.present? && reason.size <= 500
    record.user.with_lock do
      record.reload
      return record if record.status == "approved" && decision == "approved"
      if decision == "reexamine"
        raise Exchanges::Invalid, "Seule une preuve refusée peut être réexaminée." unless record.status == "rejected"
        record.update!(status: "submitted", decision: reason, reviewed_by: actor)
      else
        raise Exchanges::Invalid, "Cette preuve a déjà été examinée." unless record.status == "submitted"
        operation = Points::Rewards.grant!(user: record.user, amount: record.points, key: "achievement:#{record.id}", kind: "achievement_reward", source: record, rule: record.point_rule_version, reason: "Quête : #{record.achievement.name}".first(500)) if decision == "approved"
        record.update!(status: decision, decision: reason, reviewed_by: actor, reviewed_at: Time.current, point_operation: operation)
      end
      AuditLog.create!(actor: actor, target: record, action: "achievement.#{decision}", reason: reason)
      Notification.notify!(user: record.user, key: "achievement:#{record.id}:#{AuditLog.maximum(:id)}", title: "Votre preuve de quête a été examinée. Consultez la décision dans vos quêtes.")
    end
  end
end
