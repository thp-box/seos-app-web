class Chains
  def self.create!(actor:, name:)
    active!(actor)
    HelpChain.create!(creator: actor, name: name, chain_rule_version: ChainRuleVersion.current || raise(Exchanges::Invalid, "Aucun barème de chaîne publié."), point_rule_version: Points::Rewards.rule!)
  end

  def self.active!(user)
    raise Pundit::NotAuthorizedError unless user.active? && user.confirmed?
  end

  def self.invite!(chain:, actor:, description:)
    active!(actor)
    chain.with_lock do
      raise Pundit::NotAuthorizedError unless chain.next_provider.id == actor.id
      raise Exchanges::Invalid, "Cette chaîne est fermée ou en litige." unless chain.status == "active"
      rule = chain.chain_rule_version
      raise Exchanges::Invalid, "La longueur prévue est atteinte." if rule.length_mode == "limited" && chain.chain_services.where(status: "confirmed").count >= rule.max_links
      chain.chain_services.where(status: "invited").where("invitation_expires_at <= ?", Time.current).update_all(status: "expired")
      raise Exchanges::Invalid, "Une invitation est déjà en attente." if chain.chain_services.exists?(status: "invited")
      token = SecureRandom.urlsafe_base64(24)
      service = chain.chain_services.create!(provider: actor, description: description, position: (chain.chain_services.maximum(:position) || 0) + 1,
        invitation_token_digest: ChainService.digest(token), invitation_expires_at: 7.days.from_now)
      [ service, token ]
    end
  end

  def self.confirm!(service:, actor:)
    active!(actor)
    chain = service.help_chain
    chain.with_lock do
      service.reload
      return service if service.status == "confirmed" && service.beneficiary_id == actor.id
      raise Exchanges::Invalid, "Cette invitation est indisponible ou expirée." unless service.available?
      raise Exchanges::Invalid, "Impossible de valider son propre service ou de créer une boucle." if chain.participant?(actor)
      raise Exchanges::Invalid, "Le prestataire n’est plus actif." unless service.provider.active? && service.provider.confirmed?
      service.update!(beneficiary: actor, status: "confirmed", confirmed_at: Time.current)
      reward!(service)
      Notification.notify!(user: service.provider, key: "chain:#{service.id}:confirmed", title: "Le bénéficiaire a confirmé votre service dans la chaîne.")
      Notification.notify!(user: actor, key: "chain:#{service.id}:received", title: "Service confirmé. Vous pouvez poursuivre la chaîne en aidant une autre personne.")
      service
    end
  end

  def self.reward!(service)
    chain = service.help_chain
    rule = chain.chain_rule_version
    providers = chain.chain_services.where(status: "confirmed").order(position: :desc).map(&:provider).uniq
    providers = providers.first(rule.reward_scope == "provider_only" ? 1 : rule.rewarded_previous_links) unless rule.reward_scope == "all_eligible"
    remaining = rule.max_points_per_link
    providers.each_with_index do |recipient, index|
      next unless recipient.active? && recipient.confirmed?
      recipient.with_lock do
        prior = ChainReward.joins(:chain_service).where(recipient: recipient, chain_services: { help_chain_id: chain.id }).sum(:points)
        entries = PointEntry.joins(:point_operation).where(point_account: PointAccount.for!(recipient), amount: 1.., point_operations: { committed_at: Time.current.beginning_of_month.. })
        chain_month = entries.where(point_operations: { kind: "chain_reward" }).sum(:amount)
        total_month = entries.where(point_operations: { kind: %w[welcome_reward achievement_reward chain_reward referral_reward cycle_reward] }).sum(:amount)
        config = chain.point_rule_version.configuration
        points = [ rule.points_per_validation, remaining, rule.max_points_per_member - prior, config["chain_monthly_cap"] - chain_month, config["monthly_cap"] - total_month ].min.clamp(0, 1000)
        operation = Points::Rewards.grant!(user: recipient, amount: points, key: "chain_service:#{service.id}:#{recipient.id}", kind: "chain_reward", source: service, rule: chain.point_rule_version, reason: "Maillon n° #{service.position} confirmé") if points.positive?
        ChainReward.create!(chain_service: service, recipient: recipient, chain_rule_version: rule, points: points, reward_rank: index + 1, point_operation: operation)
        remaining -= points
      end
    end
  end

  def self.moderate!(chain:, actor:, status:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("community.manage")
    raise Exchanges::Invalid, "Statut inconnu." unless %w[active closed disputed].include?(status)
    chain.with_lock do
      chain.update!(status: status)
      AuditLog.create!(actor: actor, target: chain, action: "chain.#{status}", reason: reason)
      Notification.notify!(user: chain.creator, key: "chain:#{chain.id}:audit:#{AuditLog.maximum(:id)}", title: "Le statut de votre chaîne a changé après revue humaine.")
    end
  end

  def self.rule!(version:, actor:, action:, reason:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("community.rules")
    version.with_lock do
      version.validate!
      case action
      when "simulate"
        raise Exchanges::Invalid, "La version est déjà publiée." if version.status == "published"
        recipients = case version.reward_scope
        when "provider_only" then 1
        when "last_n_eligible" then version.rewarded_previous_links
        else version.max_links
        end
        emission = [ recipients * version.points_per_validation, version.max_points_per_link ].min
        version.update!(status: "simulated", simulation: { "fingerprint" => version.fingerprint, "maximum_per_validation" => emission, "hundred_validations" => emission * 100, "length" => version.length_mode })
      when "publish"
        raise Exchanges::Invalid, "Simulez cette version et choisissez une date future." unless version.status == "simulated" && version.simulation["fingerprint"] == version.fingerprint && version.effective_at >= Time.current
        version.update!(status: "published", published_at: Time.current)
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      AuditLog.create!(actor: actor, target: version, action: "chain.rule.#{action}", reason: reason)
    end
  end
end
