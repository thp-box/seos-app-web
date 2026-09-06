class Retention
  def self.targets(policy)
    days = policy.rules
    {
      "exports" => DataRequest.where("export_expires_at <= ?", Time.current).joins(:export_file_attachment).limit(1000).pluck(:id),
      "sessions" => LoginSession.where("revoked_at < ? OR expires_at < ?", days.fetch("sessions").days.ago, days.fetch("sessions").days.ago).limit(1000).pluck(:id),
      "notifications" => Notification.where("created_at < ?", days.fetch("notifications").days.ago).limit(1000).pluck(:id),
      "contacts" => ContactRequest.where(status: "resolved").where("resolved_at < ?", days.fetch("contacts").days.ago).limit(1000).pluck(:id),
      "invitations" => OrganizationInvitation.where(accepted_at: nil).where("expires_at < ?", days.fetch("invitations").days.ago).limit(1000).pluck(:id),
      "cookie_preferences" => CookieConsent.where("expires_at < ?", days.fetch("cookie_preferences").days.ago).limit(1000).pluck(:id)
    }
  end
  def self.policy!(policy:, actor:, action:, reason:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("privacy.rules")
    policy.with_lock do
      raise Exchanges::Invalid, "Une politique publiée est immuable." if policy.status == "published"
      policy.validate!
      if action == "simulate"
        policy.update!(status: "simulated", simulation: { "fingerprint" => policy.fingerprint, "counts" => targets(policy).transform_values(&:size) })
      elsif action == "publish"
        raise Exchanges::Invalid, "Simulation, revue juridique et seconde approbation requises." unless policy.status == "simulated" && policy.simulation["fingerprint"] == policy.fingerprint && policy.legal_reviewed_at && policy.created_by_id != actor.id && policy.effective_at >= Time.current
        policy.update!(status: "published", approved_by: actor, published_at: Time.current)
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      AuditLog.create!(actor: actor, target: policy, action: "privacy.policy.#{action}", reason: reason)
    end
  end
  def self.preview!(actor:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("privacy.rules")
    policy = RetentionPolicyVersion.current || raise(Exchanges::Invalid, "Aucune politique juridiquement validée en cours de validité.")
    PrivacyRun.create!(actor: actor, retention_policy_version: policy, targets: targets(policy), reason: reason, expires_at: 15.minutes.from_now)
  end
  def self.execute!(run:, actor:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("privacy.rules") && actor.id != run.actor_id
    run.with_lock do
      return if run.status == "executed"
      raise Exchanges::Invalid, "Prévisualisation ou politique expirée." unless run.status == "preview" && run.expires_at > Time.current && RetentionPolicyVersion.current == run.retention_policy_version
      current = targets(run.retention_policy_version)
      run.targets.each do |kind, ids|
        ids &= current.fetch(kind)
        case kind
        when "exports" then DataRequest.where(id: ids).find_each { |request| request.export_file.purge_later }
        when "sessions" then LoginSession.where(id: ids).delete_all
        when "notifications" then Notification.where(id: ids).delete_all
        when "contacts" then ContactRequest.where(id: ids).delete_all
        when "invitations" then OrganizationInvitation.where(id: ids).delete_all
        when "cookie_preferences" then CookieConsent.where(id: ids).delete_all
        end
      end
      run.update!(status: "executed", approved_by: actor, executed_at: Time.current)
      AuditLog.create!(actor: actor, target: run, action: "privacy.purge", reason: run.reason)
    end
  end
end
