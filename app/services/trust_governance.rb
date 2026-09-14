class TrustGovernance
  def self.transition!(version, actor:, action:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("trust.manage") && actor.super_admin?
    # Serialize version switches and their unique active pointer.
    actor.with_lock do
      version.reload
      from = version.status
      case action
      when "simulate"
        raise Exchanges::Invalid, "La version doit être un brouillon." unless from == "draft"
        version.update!(status: "simulated", simulation: TrustSimulation.call(version))
      when "approve"
        raise Exchanges::Invalid, "Une seconde personne doit approuver une version simulée après revue de l’AIPD et des résultats." unless from == "simulated" && actor.id != version.created_by_id
        version.update!(status: "approved", approved_by: actor)
      when "shadow"
        raise Exchanges::Invalid, "Une approbation est nécessaire." unless from == "approved"
        version.update!(status: "shadow")
      when "activate"
        raise Exchanges::Invalid, "Le calcul en ombre de tous les comptes actifs doit être terminé." unless from == "shadow" && User.where(status: "active").where.not(id: TrustScoreSnapshot.where(trust_algorithm_version: version).select(:user_id)).none?
        TrustAlgorithmVersion.where(status: "active").update_all(status: "retired")
        version.update!(status: "active", activated_at: Time.current)
      when "rollback"
        raise Exchanges::Invalid, "Seule une version précédemment active peut être restaurée." unless from == "retired" && version.activated_at
        TrustAlgorithmVersion.where(status: "active").update_all(status: "retired")
        version.update!(status: "active")
      else
        raise Exchanges::Invalid, "Transition inconnue."
      end
      AuditLog.create!(actor: actor, target: version, action: "trust.algorithm.#{action}", reason: reason, metadata: { from: from, to: version.status })
    end
    User.where(status: "active").find_each { |user| TrustRecalculationJob.perform_later(user.id) } if %w[shadow activate rollback].include?(action)
  end

  def self.correct!(event, actor:, excluded:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("trust.manage")
    event.subject.with_lock do
      TrustEventCorrection.create!(trust_event: event, actor: actor, excluded: excluded, reason: reason)
      AuditLog.create!(actor: actor, target: event, action: excluded ? "trust.exclude" : "trust.restore", reason: reason)
      Notification.notify!(user: event.subject, key: "trust:correction:#{event.trust_event_corrections.maximum(:id)}", title: "Une preuve de votre score a été corrigée après revue humaine. Un recours reste possible.")
    end
    TrustRecalculationJob.perform_later(event.subject_id)
  end

  def self.decide!(appeal, actor:, action:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("trust.manage")
    appeal.with_lock do
      raise Exchanges::Invalid, "Ce recours est déjà clôturé." unless %w[open investigating].include?(appeal.status)
      raise Exchanges::Invalid, "Décision inconnue." unless %w[investigating accepted rejected].include?(action)
      corrected = if appeal.referral
        Referral.valid_support.exists?(id: appeal.referral_id) && AuditLog.where(target: appeal.referral, action: "referral.restored", created_at: appeal.created_at..).exists?
      else
        TrustEventCorrection.where(trust_event_id: appeal.trust_score_snapshot.contributions.map { |row| row["event_id"] }).where(created_at: appeal.created_at..).exists?
      end
      if action == "accepted" && !corrected
        raise Exchanges::Invalid, "Corrigez d’abord une preuve du calcul contesté."
      end
      appeal.update!(assigned_to: actor, status: action, decision: reason, decided_at: action == "investigating" ? nil : Time.current)
      AuditLog.create!(actor: actor, target: appeal, action: "trust.appeal.#{action}", reason: reason)
      Notification.notify!(user: appeal.user, key: "trust:appeal:#{appeal.id}:#{action}", title: "Votre recours confiance a été mis à jour. La décision motivée est disponible dans votre espace.")
    end
    TrustRecalculationJob.perform_later(appeal.user_id)
  end

  def self.restore_referral!(referral, actor:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("trust.manage")
    referral.with_lock do
      raise Exchanges::Invalid, "Seul un soutien retiré peut être restauré." unless %w[objected invalidated].include?(referral.status)
      confirmed = referral.objection_deadline_at <= Time.current
      referral.update!(status: confirmed ? "confirmed" : "provisional", confirmed_at: confirmed ? Time.current : nil, invalidated_at: nil, invalidation_reason: nil)
      AuditLog.create!(actor: actor, target: referral, action: "referral.restored", reason: reason)
      Notification.notify!(user: referral.referred_user, key: "referral:#{referral.id}:restored:#{AuditLog.last.id}", title: "Un soutien a été rétabli après revue humaine.")
    end
  end
end
