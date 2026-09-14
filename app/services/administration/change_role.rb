module Administration
  class ChangeRole
    def self.call(actor:, user:, role:, reason:)
      raise Pundit::NotAuthorizedError unless actor.administrative? && actor.super_admin?
      raise ArgumentError, "Rôle non autorisé" unless %w[member admin].include?(role)
      raise ArgumentError, "Compte protégé" if user.super_admin? || user == actor
      raise ArgumentError, "Un motif est obligatoire" if reason.blank? || reason.length > 500
      user.with_lock do
        previous = user.role
        return user if previous == role
        user.update!(role: role)
        user.admin_permission_grants.where(revoked_at: nil).update_all(revoked_at: Time.current, revoked_by_id: actor.id)
        user.login_sessions.active.update_all(revoked_at: Time.current)
        AuditLog.create!(actor: actor, target: user, action: "user.role_changed", reason: reason,
          metadata: { from: previous, to: role })
      end
      user
    end
  end
end
