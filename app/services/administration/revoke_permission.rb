module Administration
  class RevokePermission
    def self.call(actor:, grant:, reason:)
      raise Pundit::NotAuthorizedError unless actor.administrative? && actor.super_admin?
      raise ArgumentError, "Un motif est obligatoire" if reason.blank? || reason.length > 500
      grant.with_lock do
        return grant if grant.revoked_at?
        grant.update!(revoked_at: Time.current, revoked_by: actor)
        AuditLog.create!(actor: actor, target: grant.user, action: "permission.revoked", reason: reason,
          metadata: { permission: grant.permission, grant_id: grant.id })
      end
      grant
    end
  end
end
