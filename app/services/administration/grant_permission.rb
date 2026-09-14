module Administration
  class GrantPermission
    def self.call(actor:, user:, permission:, reason:, expires_at:)
      raise Pundit::NotAuthorizedError unless actor.administrative? && actor.super_admin?
      raise ArgumentError, "Administrateur requis" unless user.admin?
      raise ArgumentError, "L'expiration doit être future" unless expires_at && expires_at > Time.current
      user.with_lock do
        grant = user.admin_permission_grants.find_by(permission: permission, revoked_at: nil)
        return grant if grant && (grant.expires_at.nil? || grant.expires_at > Time.current)
        grant&.update!(revoked_at: Time.current, revoked_by: actor)
        grant = user.admin_permission_grants.create!(permission: permission, reason: reason,
          expires_at: expires_at, granted_at: Time.current, granted_by: actor)
        AuditLog.create!(actor: actor, target: user, action: "permission.granted", reason: reason,
          metadata: { permission: permission, grant_id: grant.id })
        grant
      end
    end
  end
end
