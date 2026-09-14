module PointsHelpers
  def point_rules
    %w[engagement valuation].map do |family|
      PointRuleVersion.current(family) || PointRuleVersion.create!(family: family, name: "Référence #{family}", status: "published", effective_at: 2.days.ago, published_at: Time.current,
        configuration: family == "engagement" ? PointRuleVersion::DEFAULT_ENGAGEMENT : PointRuleVersion::DEFAULT_VALUATION)
    end
  end

  def fund_points(user, amount = 100)
    Points::Ledger.post!(debit: PointAccount.system!, credit: PointAccount.for!(user), amount: amount, key: SecureRandom.uuid, kind: "admin_adjustment", source: user, reason: "Provision de test")
  end

  def points_exchange(payer:, provider: create(:profile).user, amount: 20, intent: "offer")
    listing = create(:listing, user: intent == "offer" ? provider : payer, intent: intent, exchange_mode: "points", estimated_points: amount)
    actor = intent == "offer" ? payer : provider
    request = Exchanges.create!(listing: listing, actor: actor)
    Exchanges.transition!(request: request, actor: listing.user, action: "accept")
    Exchanges.transition!(request: request, actor: payer, action: "propose", terms: { scheduled_at: 1.day.from_now.iso8601, location: "Appel", mode: "remote", points: amount })
    Exchanges.transition!(request: request, actor: provider, action: "agree", version: request.agreement_version)
    request
  end
end
RSpec.configure { |config| config.include PointsHelpers }
