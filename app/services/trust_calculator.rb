class TrustCalculator
  def initialize(user:, version:, at: Time.current, events: nil, referrals: nil)
    @user, @version, @at, @config = user, version, at, version.configuration
    @events, @referrals = events, referrals
  end

  def call
    events = (@events || TrustEvent.where(subject: @user).includes(:source, :trust_event_corrections).to_a).sort_by { |event| [ event.occurred_at, event.service_request_id, event.id ] }
    @contributions = []
    pairs = Hash.new { |hash, key| hash[key] = [] }
    events.each do |event|
      excluded = event.trust_event_corrections.max_by(&:id)&.excluded
      invalid_source = event.event_kind == "review" && !event.source.revealed?
      if excluded || invalid_source || event.occurred_at > @at
        @contributions << { "event_id" => event.id, "excluded" => true, "weight" => 0 }
        next
      end
      pair = pairs[event.actor_id]
      pair << event.service_request_id unless pair.include?(event.service_request_id)
      rank = pair.index(event.service_request_id)
      repetition = rank.zero? ? 1.0 : (rank == 1 ? 0.5 : 0.2)
      recency = [ 2**(-[ (@at.to_date - event.occurred_at.to_date).to_i, 0 ].max / @config.fetch("half_life_days")), 0.25 ].max
      @contributions << { "event_id" => event.id, "actor_id" => event.actor_id, "request_id" => event.service_request_id,
        "category_id" => event.category_id, "dimension" => event.dimension, "kind" => event.event_kind,
        "value" => event.normalized_value, "weight" => (event.event_kind == "exchange" ? 1.0 : 0.8) * repetition * recency,
        "pair_factor" => repetition, "recency_factor" => recency }
    end
    rows = @contributions.reject { |row| row["excluded"] }
    exchanges = rows.select { |row| row["kind"] == "exchange" }.map(&:dup)
    cap!(exchanges.group_by { |row| row["actor_id"] }, @config.fetch("pair_cap"))
    # Each exchange/dimension has one budget, even if a criterion is duplicated.
    cap!(rows.group_by { |row| [ row["request_id"], row["dimension"] ] }, 1.0)
    cap!(rows.group_by { |row| [ row["actor_id"], row["dimension"] ] }, @config.fetch("pair_cap"))
    rows.group_by { |row| row["dimension"] }.each_value do |dimension_rows|
      diversify!(dimension_rows, "actor_id", @config.fetch("author_cap")) if dimension_rows.map { |row| row["actor_id"] }.uniq.size >= 7
    end
    partners = exchanges.map { |row| row["actor_id"] }.uniq.size
    weight = exchanges.sum { |row| row["weight"] }
    referrals = @referrals || Referral.valid_support.where(referred_user: @user).to_a
    referral_weight = [ referrals.count, 10 ].min * @config.fetch("referral_weight")
    established = weight >= @config.fetch("exchange_threshold") && partners >= @config.fetch("partner_threshold")
    global_rows = rows.map(&:dup)
    diversify!(global_rows, "category_id", @config.fetch("category_cap")) if global_rows.map { |row| row["category_id"] }.uniq.size >= 2
    dimensions = dimension_results(global_rows)
    # Aggregate sufficient statistics, not rounded posterior scores; referrals remain global only.
    applicable = @config.fetch("dimensions").slice(*dimensions.keys)
    denominator = applicable.values.sum
    evidence = dimensions.sum { |key, value| value.fetch("weight") * applicable.fetch(key) } / (denominator.nonzero? || 1)
    positive = dimensions.sum { |key, value| value.fetch("positive") * applicable.fetch(key) } / (denominator.nonzero? || 1)
    score = posterior(positive + referral_weight, evidence + referral_weight)
    status = established ? "published" : (referral_weight.positive? ? "provisional" : "insufficient_data")
    categories = rows.group_by { |row| row["category_id"] }.filter_map do |category_id, category_rows|
      confirmed = exchanges.select { |row| row["category_id"] == category_id }
      next unless category_id && confirmed.sum { |row| row["weight"] } >= @config.fetch("category_threshold") && confirmed.map { |row| row["actor_id"] }.uniq.size >= @config.fetch("category_partners")
      values = dimension_results(category_rows)
      weights = @config.fetch("dimensions").slice(*values.keys)
      [ category_id.to_s, { "score" => (values.sum { |key, value| value.fetch("score") * weights.fetch(key) } / weights.values.sum).round, "dimensions" => values } ]
    end.to_h
    confidence = 1 - Math.exp(-(evidence + referral_weight) / 8.0)
    result = { "score" => status == "insufficient_data" ? nil : score, "status" => status,
      "confidence" => confidence, "confidence_label" => !established || confidence < 0.5 ? "Données limitées" : (confidence < 0.8 ? "Données modérées" : "Données solides"),
      "exchange_count" => exchanges.map { |row| row["request_id"] }.uniq.size, "partners" => partners,
      "exchange_weight" => weight, "referral_count" => referrals.count, "confirmed_referrals" => referrals.count { |referral| referral.status == "confirmed" },
      "referral_weight" => referral_weight, "dimensions" => established ? dimensions : {}, "categories" => established ? categories : {},
      "version" => @version.version, "calculated_on" => @at.to_date.iso8601 }
    [ result, @contributions ]
  end

  private

  def posterior(positive, weight)
    (100 * (@config.fetch("prior") + positive) / (2 * @config.fetch("prior") + weight)).round.clamp(0, 100)
  end

  def dimension_results(rows)
    rows.group_by { |row| row["dimension"] }.transform_values do |items|
      weight = items.sum { |row| row["weight"] }
      positive = items.sum { |row| row["weight"] * row["value"] }
      { "score" => posterior(positive, weight), "weight" => weight, "positive" => positive, "confidence" => 1 - Math.exp(-weight / 8.0) }
    end
  end

  def cap!(groups, maximum)
    groups.each_value do |items|
      total = items.sum { |row| row["weight"] }
      items.each { |row| row["weight"] *= maximum / total } if total > maximum
    end
  end

  def diversify!(rows, key, fraction)
    groups = rows.group_by { |row| row[key] }
    # Water filling: largest allowed contribution is fraction of the final total.
    100.times do
      total = rows.sum { |row| row["weight"] }
      break if groups.values.all? { |items| items.sum { |row| row["weight"] } <= total * fraction + 1e-10 }
      cap!(groups, total * fraction)
    end
  end
end
