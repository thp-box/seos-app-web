module Points
  class Adjustments
    def self.preview!(user:, actor:, amount:, reason:)
      raise Pundit::NotAuthorizedError unless actor.permission?("points.adjust")
      user.with_lock do
        account = PointAccount.for!(user)
        PointAdjustment.create!(user: user, proposed_by: actor, amount: amount, reason: reason, balance_before: account.balance, expires_at: 10.minutes.from_now)
      end
    end

    def self.commit!(adjustment, actor:)
      raise Pundit::NotAuthorizedError unless actor.permission?("points.adjust")
      adjustment.with_lock do
        return adjustment.point_operation if adjustment.point_operation
        if adjustment.amount.abs > 100
          raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.id != adjustment.proposed_by_id
        else
          raise Pundit::NotAuthorizedError unless actor.id == adjustment.proposed_by_id || actor.super_admin?
        end
        account = PointAccount.for!(adjustment.user)
        raise Exchanges::Invalid, "L’aperçu a expiré ou le solde a changé. Préparez un nouvel aperçu." unless adjustment.expires_at > Time.current && adjustment.balance_before == account.balance
        debit, credit = adjustment.amount.positive? ? [ PointAccount.system!, account ] : [ account, PointAccount.system! ]
        operation = Ledger.post!(debit: debit, credit: credit, amount: adjustment.amount.abs, key: "adjustment:#{adjustment.id}", kind: "admin_adjustment", source: adjustment, reason: adjustment.reason, initiator: actor)
        adjustment.update!(approved_by: actor, point_operation: operation)
        AuditLog.create!(actor: actor, target: operation, action: "points.adjustment", reason: adjustment.reason, metadata: { from: adjustment.balance_before, to: adjustment.balance_before + adjustment.amount })
        operation
      end
    end
  end
end
