module Points
  class Rules
    def self.simulate!(version, actor:, reason:)
      raise Pundit::NotAuthorizedError unless actor.permission?("points.rules")
      version.with_lock do
        raise Exchanges::Invalid, "Simulez une version non publiée." if version.status == "published"
        version.validate!
        result = simulation_result(version)
        current = PointRuleVersion.current(version.family)
        version.update!(status: "simulated", simulation: { "digest" => digest(version), "result" => result, "previous_version_id" => current&.id, "previous_configuration" => current&.configuration })
        AuditLog.create!(actor: actor, target: version, action: "points.rules.simulate", reason: reason)
      end
    end

    def self.simulation_result(version)
      if version.family == "valuation"
          version.configuration.fetch("brackets").flat_map { |row| [ row["from_cents"], row["to_cents"] ] }.uniq.map { |cents| { "cents" => cents, "estimate" => version.estimate(cents) } }
      else
          config = version.configuration
          { "welcome" => config["welcome"], "ten_cycles" => config["cycle"].transform_values { |amount| amount * 10 }, "maximum_monthly_rewards" => config["monthly_cap"], "maximum_monthly_chain" => config["chain_monthly_cap"] }
      end
    end

    def self.publish!(version, actor:, reason:)
      raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("points.rules")
      version.with_lock do
        raise Exchanges::Invalid, "Une simulation correspondant à cette version et une date future sont requises." unless version.status == "simulated" && version.simulation["digest"] == digest(version) && version.effective_at >= Time.current
        version.update!(status: "published", published_at: Time.current)
        AuditLog.create!(actor: actor, target: version, action: "points.rules.publish", reason: reason)
      end
    end

    def self.rollback!(version, actor:, reason:)
      raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("points.rules")
      raise Exchanges::Invalid, "Choisissez une version publiée." unless version.status == "published"
      PointRuleVersion.transaction do
        copy = PointRuleVersion.create!(family: version.family, name: "Retour — #{version.name}".first(100), configuration: version.configuration, effective_at: 1.minute.from_now, created_by: actor)
        simulate!(copy, actor: actor, reason: reason)
        publish!(copy, actor: actor, reason: reason)
        copy
      end
    end

    def self.digest(version) = Digest::SHA256.hexdigest([ version.family, version.configuration, version.effective_at.iso8601(6) ].to_json)
  end
end
