# Versioned reference data only. No balances or rewards are manufactured by seeds.
%w[engagement valuation].each do |family|
  next if PointRuleVersion.where(family: family).exists?
  version = PointRuleVersion.create!(family: family, name: "SEOS #{family} V1", effective_at: Time.utc(2026, 9, 5), configuration: family == "engagement" ? PointRuleVersion::DEFAULT_ENGAGEMENT : PointRuleVersion::DEFAULT_VALUATION)
  version.update!(status: "simulated", simulation: { "digest" => Points::Rules.digest(version), "result" => Points::Rules.simulation_result(version), "reference_seed" => true })
  version.update!(status: "published", published_at: Time.current)
end
PointAccount.system!
