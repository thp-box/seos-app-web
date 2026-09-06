require "rails_helper"

RSpec.describe Missions do
  let(:owner) { create(:profile).user }
  let(:organization) { organization_space(owner: owner) }
  let(:admin) { create(:user, :super_admin) }
  let(:candidate) { create(:profile).user }
  let(:mission) { world_mission(organization: organization) }
  def apply(user = candidate, **dates)
    described_class.apply!(mission: mission, actor: user, message: "Je souhaite aider", starts_on: dates[:starts_on] || Date.current + 3, ends_on: dates[:ends_on] || Date.current + 8)
  end

  it "valide les bornes en base et serveur, et réserve la publication au super-admin" do
    record = organization.volunteer_missions.new
    described_class.save!(mission: record, actor: owner, attributes: mission_attributes)
    expect(record.status).to eq("draft")
    record.daily_contribution_euros = "15,00"
    expect(record.daily_contribution_cents).to eq(1500)
    record.daily_contribution_euros = "15.001"
    expect(record).not_to be_valid
    record.reload
    expect { described_class.save!(mission: record, actor: candidate, attributes: { title: "Vol" }) }.to raise_error(Pundit::NotAuthorizedError)
    expect { record.update!(daily_contribution_cents: 1501) }.to raise_error(ActiveRecord::RecordInvalid)
    record.reload
    expect { record.update_columns(daily_contribution_cents: -1) }.to raise_error(ActiveRecord::StatementInvalid)
    described_class.transition!(mission: record.reload, actor: owner, status: "pending_review", reason: "Prêt")
    expect { described_class.transition!(mission: record, actor: owner, status: "published", reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    described_class.transition!(mission: record, actor: admin, status: "published", reason: "Conditions vérifiées")
    expect(record.publicly_visible?).to be(true)
    described_class.transition!(mission: record, actor: owner, status: "paused", reason: "Pause")
    expect(record.publicly_visible?).to be(false)
    expect { described_class.transition!(mission: record, actor: admin, status: "unknown", reason: "Non") }.to raise_error(Exchanges::Invalid)
    record.assign_attributes(ends_on: Date.current - 1)
    expect(record.valid?(:publication)).to be(false)
  end

  it "borne les dates, refuse le doublon et ses propres missions, puis compte la capacité simultanée" do
    expect { apply(candidate, ends_on: Date.current + 2) }.to raise_error(Exchanges::Invalid)
    expect { apply(owner) }.to raise_error(Pundit::NotAuthorizedError)
    first = apply
    expect { apply }.to raise_error(ActiveRecord::RecordNotUnique)
    expect { described_class.decide!(application: first, actor: candidate, status: "accepted", reason: "Auto") }.to raise_error(Pundit::NotAuthorizedError)
    described_class.decide!(application: first, actor: owner, status: "accepted", reason: "Accueil confirmé")
    described_class.decide!(application: first, actor: owner, status: "accepted", reason: "Rejeu")
    overlapping = apply(create(:user))
    expect { described_class.decide!(application: overlapping, actor: owner, status: "accepted", reason: "Complet") }.to raise_error(Exchanges::Invalid, /capacité/)
    following = apply(create(:user), starts_on: Date.current + 9, ends_on: Date.current + 11)
    described_class.decide!(application: following, actor: owner, status: "accepted", reason: "Séjour suivant")
    expect(mission.mission_applications.where(status: "accepted").count).to eq(2)
    expect { described_class.save!(mission: mission.reload, actor: owner, attributes: { daily_contribution_cents: 1500 }) }.to raise_error(Exchanges::Invalid, /en cours/)
    described_class.decide!(application: first, actor: candidate, status: "withdrawn", reason: "Indisponible")
    expect { described_class.decide!(application: first, actor: owner, status: "accepted", reason: "Revenir") }.to raise_error(Exchanges::Invalid)
  end

  it "limite les conversations aux responsables et au candidat, sans récompense ni données annexes" do
    application = apply
    editor = create(:organization_membership, organization: organization, role: :editor).user
    expect { described_class.message!(application: application, actor: editor, body: "Vol", key: "a") }.to raise_error(Pundit::NotAuthorizedError)
    2.times { described_class.message!(application: application, actor: candidate, body: "Ma question privée", key: "delivery") }
    expect(application.mission_messages.count).to eq(1)
    expect { described_class.message!(application: application, actor: candidate, body: "Autre", key: "delivery") }.to raise_error(Exchanges::Invalid)
    described_class.message!(application: application, actor: owner, body: "Bienvenue", key: "reply")
    expect(application.mission_messages.last.ciphertext_for(:body)).not_to include("Bienvenue")
    expect { application.update_columns(starts_on: Date.current) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { application.mission_messages.last.update!(body: "Modifié") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    described_class.decide!(application: application, actor: owner, status: "rejected", reason: "Pas de place")
    expect { described_class.message!(application: application, actor: owner, body: "Non", key: "closed") }.to raise_error(Exchanges::Invalid)
    expect(PointOperation.count).to eq(0)
    expect(TrustEvent.count).to eq(0)
  end

  it "coupe la publication et les candidatures lorsque l’association ou le parcours est suspendu" do
    application = apply
    organization.update!(status: "suspended")
    expect(mission.reload.publicly_visible?).to be(false)
    expect { apply(create(:user)) }.to raise_error(Exchanges::Invalid)
    expect(application.reload.manageable_by?(owner)).to be(false)
    organization.update!(status: "verified")
    FeatureFlag.create!(key: "voyage_enabled", enabled: false)
    expect { described_class.transition!(mission: mission, actor: admin, status: "published", reason: "Non") }.to raise_error(Exchanges::Invalid)
    expect { described_class.decide!(application: application.reload, actor: owner, status: "accepted", reason: "Non") }.to raise_error(Exchanges::Invalid)
    expect { described_class.save!(mission: world_mission(organization: organization_space(kind: "company")), actor: admin, attributes: {}) }.to raise_error(Exchanges::Invalid)
  end
end
