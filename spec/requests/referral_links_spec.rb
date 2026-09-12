require "rails_helper"

RSpec.describe "Parrainage par lien permanent", type: :request do
  it "conserve l’invitation après une erreur de formulaire et rattache après confirmation" do
    sponsor = create(:user, created_at: 31.days.ago)
    link = Referrals.link_for!(sponsor)
    get referral_invitation_path(token: link.token)
    expect(response).to redirect_to(new_user_registration_path)
    post user_registration_path, params: { user: { email: "filleul@example.org", password: "court", password_confirmation: "court" } }
    expect(response).to have_http_status(:unprocessable_content)
    post user_registration_path, params: { user: { email: "filleul@example.org", password: "UnMotDePasseSolide!42", password_confirmation: "UnMotDePasseSolide!42" } }
    newbie = User.find_by!(email: "filleul@example.org")
    expect(newbie.pending_referral_link_id).to eq(link.id)
    expect(Referral.where(referred_user: newbie)).to be_empty
    newbie.confirm
    expect(Referral.where(referred_user: newbie).sole.referrer).to eq(sponsor)
    expect(newbie.reload.pending_referral_link_id).to be_nil
    expect { newbie.confirm }.not_to change(Referral, :count)
  end

  it "réutilise un seul lien pour un nombre illimité de filleuls" do
    sponsor = create(:user, created_at: 31.days.ago)
    link = Referrals.link_for!(sponsor)
    12.times { Referrals.register_link!(create(:user), link.id) }
    expect(link.referrals.count).to eq(12)
    expect(Referrals.link_for!(sponsor)).to eq(link)
    expect(ReferralLink.where(owner: sponsor).count).to eq(1)
    travel 60.days
    expect(Referrals.link_for!(sponsor)).to eq(link)
    get referral_invitation_path(token: link.token)
    expect(response).to redirect_to(new_user_registration_path)
  end

  it "ne remplace pas un parrain, refuse l’auto-parrainage et désactive un lien si son propriétaire est suspendu" do
    sponsor = create(:user, created_at: 31.days.ago)
    link = Referrals.link_for!(sponsor)
    expect { Referrals.register_link!(sponsor, link.id) }.not_to change(Referral, :count)
    newbie = create(:user)
    Referrals.register_link!(newbie, link.id)
    other = Referrals.link_for!(create(:user, created_at: 31.days.ago))
    expect { Referrals.register_link!(newbie, other.id) }.not_to change(Referral, :count)
    sponsor.update!(status: :suspended)
    get referral_invitation_path(token: link.token)
    expect(response).to redirect_to(new_user_registration_path)
    follow_redirect!
    expect(response.body).not_to include("Votre invitation de parrainage est enregistrée")
  end

  it "réserve le réglage au super-admin et synchronise texte, durée réelle et exemption" do
    user = create(:user, created_at: 5.days.ago)
    admin = create(:user, :super_admin)
    login(admin)
    post admin_trust_index_path, params: { operation: "referral_settings", minimum_age_days: 4 }
    expect(response).to have_http_status(:see_other)
    expect(Referrals.eligible?(user)).to be(true)
    expect(AuditLog.last.action).to eq("referral.settings")
    post admin_trust_index_path, params: { operation: "referral_settings", minimum_age_days: -1 }
    expect(response).to have_http_status(:unprocessable_content)
    expect(ReferralSetting.minimum_age_days).to eq(4)
    post admin_trust_index_path, params: { operation: "referral_settings", minimum_age_days: 10 }
    expect(Referrals.eligible?(user)).to be(false)
    exempt_sponsor(user)
    expect(Referrals.eligible?(user)).to be(true)
    delete destroy_user_session_path
    login(user)
    get account_trust_path
    expect(response.body).to include("10 jours d’ancienneté")
    post admin_trust_index_path, params: { operation: "referral_settings", minimum_age_days: 0 }
    expect(response).to have_http_status(:forbidden)
    expect(ReferralSetting.minimum_age_days).to eq(10)
  end

  it "interdit le réglage à un administrateur délégué et ne rattache pas un compte connecté par simple visite" do
    admin = create(:user, role: :admin)
    super_admin = create(:user, :super_admin)
    AdminPermissionGrant.create!(user: admin, granted_by: super_admin, permission: "trust.manage", reason: "Gestion des recours", granted_at: Time.current)
    login(admin)
    post admin_trust_index_path, params: { operation: "referral_settings", minimum_age_days: 0 }
    expect(response).to have_http_status(:forbidden)
    expect(ReferralSetting.minimum_age_days).to eq(30)
    link = Referrals.link_for!(create(:user, created_at: 31.days.ago))
    expect { get referral_invitation_path(token: link.token) }.not_to change(Referral, :count)
    expect(response).to redirect_to(account_trust_path)
    expect(admin.reload.pending_referral_link_id).to be_nil
  end

  it "récompense chaque nouveau filleul qualifié une seule fois" do
    point_rules
    sponsor = create(:user, created_at: 31.days.ago)
    link = Referrals.link_for!(sponsor)
    2.times do
      newbie = create(:user)
      Referrals.register_link!(newbie, link.id)
      newbie.update!(created_at: 31.days.ago)
      2.times { completed_exchange(newbie) }
    end
    travel 73.hours
    Referrals.mature!
    Points::Rewards.sync!(sponsor)
    expect(PointAccount.for!(sponsor).balance).to eq(30)
    expect { Points::Rewards.sync!(sponsor) }.not_to change(PointOperation, :count)
  end
end
