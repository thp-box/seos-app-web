class Operations
  def self.preview!(actor:, ids:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("operations.manage")
    ids = ids.map(&:to_i).uniq
    raise Exchanges::Invalid, "Sélectionnez entre 1 et 20 membres." unless ids.size.between?(1, 20)
    users = User.where(id: ids).order(:id).to_a
    raise Exchanges::Invalid, "Seuls les membres actifs peuvent être suspendus." unless users.size == ids.size && users.all? { |user| user.member? && user.active? && user.id != actor.id }
    BulkOperation.transaction do
      operation = BulkOperation.create!(actor: actor, targets: users.to_h { |user| [ user.id.to_s, user.updated_at.iso8601(6) ] }, reason: reason, expires_at: 15.minutes.from_now)
      AuditLog.create!(actor: actor, target: operation, action: "operations.preview", reason: reason)
      operation
    end
  end
  def self.execute!(operation:, actor:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("operations.manage") && actor.id != operation.actor_id
    operation.with_lock do
      return if operation.executed_at
      raise Exchanges::Invalid, "La prévisualisation a expiré." unless operation.expires_at > Time.current
      users = User.where(id: operation.targets.keys).order(:id).lock.to_a
      raise Exchanges::Invalid, "La sélection a changé : recommencez." unless users.size == operation.targets.size && users.all? { |u| u.member? && u.active? && u.updated_at.iso8601(6) == operation.targets[u.id.to_s] }
      users.each do |user|
        user.update!(status: "suspended")
        user.login_sessions.active.update_all(revoked_at: Time.current)
        AuditLog.create!(actor: actor, target: user, action: "operations.suspend", reason: operation.reason)
      end
      operation.update!(executed_at: Time.current, approved_by: actor)
    end
  end
end
