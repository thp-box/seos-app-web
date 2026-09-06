require "rails_helper"

RSpec.describe PartnershipWorkflow do
  let(:owner) { create(:profile).user }
  let(:organization) { organization_space(owner: owner, kind: "company") }
  let(:admin) { create(:user, :super_admin) }
  let(:record) { organization.partnerships.new }

  it "sépare les brouillons de la publication, vérifie les liens et expire les périodes" do
    described_class.save!(record: record, actor: owner, attributes: partnership_attributes)
    expect(record.publicly_visible?).to be(false)
    expect { described_class.transition!(record: record, actor: owner, status: "published", reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    described_class.transition!(record: record, actor: owner, status: "pending_review", reason: "Prêt")
    described_class.transition!(record: record, actor: admin, status: "published", reason: "Accord vérifié")
    expect(record.publicly_visible?).to be(true)
    travel_to 30.days.from_now do
      expect(record.publicly_visible?).to be(false)
      expect(record.valid?(:publication)).to be(false)
    end
    %w[javascript:alert(1) http://example.org https://name:password@example.org http://].each do |url|
      record.cta_url = url
      expect(record).not_to be_valid
    end
    record.reload
    described_class.save!(record: record, actor: owner, attributes: { public_description: "Autre présentation" })
    expect(record.status).to eq("draft")
    described_class.transition!(record: record, actor: admin, status: "archived", reason: "Fin de l’accord")
    expect(record.publicly_visible?).to be(false)
    expect { described_class.transition!(record: record, actor: admin, status: "invalid", reason: "Non") }.to raise_error(Exchanges::Invalid)
  end

  it "réserve les types au super-admin, l’édition aux habilités et respecte les flags" do
    outsider = create(:user)
    expect { described_class.save!(record: record, actor: outsider, attributes: partnership_attributes) }.to raise_error(Pundit::NotAuthorizedError)
    expect { described_class.save!(record: record, actor: owner, attributes: partnership_attributes.merge(kind: "support")) }.to raise_error(Pundit::NotAuthorizedError)
    described_class.save!(record: record, actor: admin, attributes: partnership_attributes.merge(kind: "technical", position: 2))
    expect(record.kind).to eq("technical")
    FeatureFlag.create!(key: "partnerships_enabled", enabled: false)
    expect { described_class.transition!(record: record, actor: admin, status: "published", reason: "Non") }.to raise_error(Exchanges::Invalid)
    FeatureFlag.find_by!(key: "partnerships_enabled").update!(enabled: true)
    organization.update!(status: "suspended")
    expect(record.reload.valid?(:publication)).to be(false)
    expect { described_class.transition!(record: record, actor: admin, status: "published", reason: "Non") }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
