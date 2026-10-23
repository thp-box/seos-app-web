module TrustHelpers
  def trust_version(status: "active", creator: create(:user, :super_admin))
    TrustAlgorithmVersion.create!(version: SecureRandom.hex(5), status: status, created_by: creator,
      configuration: TrustAlgorithmVersion::DEFAULT_CONFIGURATION, explanation: "Formule V1 testée")
  end

  def completed_exchange(user, partner: create(:profile).user, at: Time.current, category: create(:category))
    listing = create(:listing, user: partner, category: category)
    create(:service_request, listing: listing, requester: user, provider: partner, status: "completed",
      completed_at: at, requester_confirmed_at: at, provider_confirmed_at: at)
  end

  def exempt_sponsor(user = create(:user))
    user
  end

  def support(user, sponsor: exempt_sponsor)
    raw = Referrals.issue!(sponsor)
    Referrals.claim!(user, raw)
    Referral.where(referred_user: user).order(:id).last
  end
end
RSpec.configure { |config| config.include TrustHelpers }
