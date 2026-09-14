module Points
  class Ledger
    def self.post!(debit:, credit:, amount:, key:, kind:, source:, reason:, initiator: nil, rule: nil, reversed_operation: nil)
      raise Exchanges::Invalid, "Deux comptes distincts et un montant entier positif sont nécessaires." unless debit.id != credit.id && amount.is_a?(Integer) && (1..999_999).cover?(amount)
      PointOperation.transaction do
        # SQLite immediate transactions serialize writers; deterministic order also documents lock intent.
        accounts = PointAccount.where(id: [ debit.id, credit.id ]).order(:id).lock.index_by(&:id)
        existing = PointOperation.find_by(idempotency_key: key)
        if existing
          expected = { debit.id => -amount, credit.id => amount }
          raise Exchanges::Invalid, "La clé correspond à une autre opération." unless existing.status == "committed" && existing.kind == kind && existing.source == source && existing.point_rule_version_id == rule&.id && existing.point_entries.pluck(:point_account_id, :amount).to_h == expected
          return existing
        end
        raise Exchanges::Invalid, "Solde Points Services insuffisant." if accounts.fetch(debit.id).kind == "user" && accounts.fetch(debit.id).balance < amount
        operation = PointOperation.create!(kind: kind, source: source, idempotency_key: key, reason: reason, initiator: initiator, point_rule_version: rule, reversed_operation: reversed_operation)
        { debit.id => -amount, credit.id => amount }.each do |id, delta|
          operation.point_entries.create!(point_account_id: id, amount: delta, balance_after: accounts.fetch(id).balance + delta)
        end
        operation.update!(status: "committed", committed_at: Time.current)
        accounts.values.filter_map(&:user).each { |user| Notification.notify!(user: user, key: "points:#{operation.id}", title: "Votre portefeuille Points Services a été mis à jour. Consultez le montant et le motif dans votre historique.") }
        operation
      end
    end

    def self.reverse!(operation, actor:, reason:)
      raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("points.adjust")
      raise Exchanges::Invalid, "Seule une opération validée non inverse peut être compensée." unless operation.status == "committed" && operation.kind != "reversal"
      operation.with_lock do
        debit, credit = operation.point_entries.order(:amount).to_a
        inverse = post!(debit: credit.point_account, credit: debit.point_account, amount: credit.amount, key: "reversal:#{operation.id}", kind: "reversal", source: operation, reason: reason, initiator: actor, rule: operation.point_rule_version, reversed_operation: operation)
        AuditLog.create!(actor: actor, target: inverse, action: "points.reversal", reason: reason) unless AuditLog.exists?(target: inverse, action: "points.reversal")
        inverse
      end
    end
  end
end
