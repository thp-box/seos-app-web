require "rails_helper"
RSpec.describe OrganizationPolicy, :"F-004", type: :policy do
  let(:organization) { create(:organization) }
  [ nil, :member, :admin, :super_admin ].each do |role|
    it "refuse un accès sans membership : #{role || 'visiteur'}" do
      user = create(:user, role: role) if role
      expect(described_class.new(user, organization).show?).to be(false)
    end
  end
  %i[owner manager editor].each do |role|
    it "applique les droits #{role} à la bonne organisation" do
      membership = create(:organization_membership, organization: organization, role: role)
      policy = described_class.new(membership.user, organization)
      expect(policy.show?).to be(true)
      expect(policy.team?).to eq(role != :editor)
      expect(described_class.new(membership.user, create(:organization)).show?).to be(false)
      membership.update!(status: :revoked)
      expect(described_class.new(membership.user, organization).show?).to be(false)
    end
  end

  it "refuse une organisation suspendue ou un membre inactif" do
    membership = create(:organization_membership, organization: organization)
    organization.update!(status: :suspended)
    expect(described_class.new(membership.user, organization).show?).to be(false)
    organization.update!(status: :verified)
    membership.user.update!(status: :suspended)
    expect(described_class.new(membership.user, organization).show?).to be(false)
  end

  it "interdit les actions inconnues et les scopes par défaut" do
    user = create(:user)
    policy = ApplicationPolicy.new(user, organization)
    expect([ policy.index?, policy.show?, policy.create?, policy.update?, policy.destroy? ]).to all(be(false))
    expect(ApplicationPolicy::Scope.new(user, Organization).resolve).to be_empty
  end
end
