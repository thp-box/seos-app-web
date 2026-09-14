module Points
  class Settlement
    def self.call!(request, actor:)
      raise Pundit::NotAuthorizedError unless request.participant?(actor)
      raise Exchanges::Invalid, "L’échange et son montant doivent être confirmés par les deux participants." unless request.completed? && request.agreed? && request.requester_confirmed_at && request.provider_confirmed_at
      raise Exchanges::Invalid, "Les deux comptes doivent être actifs et confirmés." unless User.where(id: [ request.requester_id, request.provider_id ], status: "active").where.not(confirmed_at: nil).count == 2
      terms = request.agreement
      raise Exchanges::Invalid, "Renégociez les modalités Points Services avant confirmation." unless terms["exchange_mode"] == "points" && [ terms["payer_id"], terms["payee_id"] ].sort == [ request.requester_id, request.provider_id ].sort
      raise Exchanges::Invalid, "Un litige en cours bloque le transfert." if request.blocked? || Report.where(reportable: request, status: %w[open investigating]).exists?
      Ledger.post!(debit: PointAccount.for!(User.find(terms["payer_id"])), credit: PointAccount.for!(User.find(terms["payee_id"])), amount: terms["points"],
        key: "transfer:#{request.id}", kind: "service_transfer", source: request, initiator: actor,
        rule: PointRuleVersion.find(terms.fetch("valuation_version_id")), reason: "Transfert de #{terms['points']} PS — accord #{request.agreement_version}, échange n° #{request.id}")
    end
  end
end
