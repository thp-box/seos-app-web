class TrustSimulation
  Event = Data.define(:id, :actor_id, :service_request_id, :category_id, :dimension, :event_kind, :normalized_value, :occurred_at, :trust_event_corrections)
  Support = Data.define(:status)

  def self.call(version)
    at = Time.current.beginning_of_day
    scores = [ 1, 3, 5, 10 ].map do |count|
      TrustCalculator.new(user: nil, version: version, at: at, events: [], referrals: Array.new(count) { Support.new("confirmed") }).call.first.fetch("score")
    end
    raise Exchanges::Invalid, "Les repères de simulation divergent." unless scores == [ 53, 58, 62, 69 ]
    scenarios = { "newcomer" => [], "independent_partners" => (1..10).to_a, "repeated_pair" => Array.new(20, 1), "inactive_member" => (1..10).to_a }
    checks = scenarios.transform_values.with_index do |partners, scenario_index|
      events = partners.each_with_index.map do |partner, index|
        Event.new(id: index + 1, actor_id: partner, service_request_id: index + 1, category_id: 1, dimension: "reliability", event_kind: "exchange", normalized_value: 1.0,
          occurred_at: scenario_index == 3 ? at - 1096.days : at, trust_event_corrections: [])
      end
      arguments = { user: nil, version: version, at: at, referrals: [] }
      forward = TrustCalculator.new(**arguments, events: events).call
      reverse = TrustCalculator.new(**arguments, events: events.reverse).call
      raise Exchanges::Invalid, "Le calcul dépend de l’ordre des preuves." unless forward == reverse
      forward.first.slice("score", "status", "partners", "exchange_weight", "confidence")
    end
    raise Exchanges::Invalid, "Le plafond de paire ne protège pas les nouveaux profils." unless checks.fetch("repeated_pair").fetch("score").nil?
    { "referral_scores" => scores, "scenarios" => checks, "simulated_at" => at.iso8601 }
  end
end
