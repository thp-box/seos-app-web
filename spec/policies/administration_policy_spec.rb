require "rails_helper"
RSpec.describe AdministrationPolicy, :"F-004", type: :policy do
  shared_examples "no administrative access" do
    it "refuse chaque section et toute exclusivité super-admin" do
      policy = described_class.new(account, :administration)
      expect([ policy.show?, policy.users?, policy.audit?, policy.super_admin? ]).to all(be(false))
    end
  end
  context("visiteur") { let(:account) { nil }; include_examples "no administrative access" }
  context("membre") { let(:account) { create(:user) }; include_examples "no administrative access" }
  context "association" do
    let(:account) { create(:organization_membership, role: :owner).user }
    include_examples "no administrative access"
  end
  context "partenaire" do
    let(:account) { create(:organization_membership, organization: create(:organization, kind: :company)).user }
    include_examples "no administrative access"
  end
  context "admin suspendu" do
    let(:account) { create(:user, :admin, status: :suspended) }
    include_examples "no administrative access"
  end
  context "super-admin non confirmé" do
    let(:account) { create(:user, :super_admin, :unconfirmed) }
    include_examples "no administrative access"
  end

  it "limite l'admin aux permissions effectives" do
    admin = create(:user, :admin)
    policy = described_class.new(admin, :administration)
    expect(policy.show?).to be(true)
    expect(policy.users?).to be(false)
    expect(policy.audit?).to be(false)
    expect(policy.super_admin?).to be(false)
    permission = create(:admin_permission_grant, user: admin, permission: "users.read")
    expect(policy.users?).to be(true)
    permission.update!(expires_at: 1.second.ago)
    expect(policy.users?).to be(false)
    permission.update!(expires_at: nil)
    expect(policy.users?).to be(true)
    permission.update!(revoked_at: Time.current)
    expect(policy.users?).to be(false)
  end

  it "accorde toutes les sections au super-admin" do
    policy = described_class.new(create(:user, :super_admin), :administration)
    expect([ policy.show?, policy.users?, policy.audit?, policy.super_admin? ]).to all(be(true))
  end
end
