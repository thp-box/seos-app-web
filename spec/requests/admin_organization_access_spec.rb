require "rails_helper"

RSpec.describe "Gestion des demandes par un admin", type: :request do
  it "ouvre les demandes et permet leur examen sans permission individuelle" do
    admin = create(:user, :admin)
    organization = organization_space(status: "pending", published_at: nil, request_kind: "community_mission")
    login admin
    get admin_root_path
    expect(response.body).to include("Associations et partenariats", "Gérer les demandes")
    get admin_network_index_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(organization.name)
    get admin_network_path(organization.id, section: "organizations")
    expect(response.body).to include("review-#{organization.id}-status")
    expect(response.body).not_to include(organization.legal_email, organization.registration_number)
    post admin_network_index_path, params: { operation: "review", record_id: organization.id, status: "verified", reason: "" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.reload).to be_pending
    post admin_network_index_path, params: { operation: "review", record_id: organization.id, status: "verified", reason: "Dossier examiné" }
    expect(response).to have_http_status(:see_other)
    expect(organization.reload).to be_verified
    expect(AuditLog.where(target: organization, action: "organization.verified", actor: admin)).to exist
    expect(Notification.where(user_id: organization.organization_memberships.pluck(:user_id), category: "organizations")).to exist
    post admin_network_index_path, params: { operation: "review", record_id: organization.id, status: "rejected", reason: "Dossier non recevable" }
    expect(organization.reload).to be_rejected
  end

  it "permet à un admin de valider puis archiver une proposition de partenariat" do
    admin = create(:user, :admin)
    organization = organization_space(kind: "company", request_kind: "partnership")
    partnership = organization.partnerships.create!(partnership_attributes.merge(status: "pending_review"))
    FeatureFlag.find_or_initialize_by(key: "partnerships_enabled").update!(enabled: true)
    login admin
    post admin_network_index_path, params: { operation: "partnership_transition", record_id: partnership.id, status: "published", reason: "Proposition retenue" }
    expect(response).to have_http_status(:see_other)
    expect(partnership.reload.status).to eq("published")
    expect(partnership.approved_by).to eq(admin)
    post admin_network_index_path, params: { operation: "partnership_transition", record_id: partnership.id, status: "archived", reason: "Collaboration terminée" }
    expect(partnership.reload.status).to eq("archived")
  end

  it "conserve les limites sur les données privées et les actions exceptionnelles" do
    admin = create(:user, :admin)
    organization = organization_space
    login admin
    [
      { operation: "reveal", record_id: organization.id, reason: "Tentative" },
      { operation: "recover_owner", record_id: organization.id, user_id: admin.id, reason: "Tentative" },
      { operation: "review", record_id: organization.id, status: "verified", kind: "company", reason: "Tentative" },
      { operation: "flag", key: "partnerships_enabled", enabled: "1", reason: "Tentative" }
    ].each do |parameters|
      post admin_network_index_path, params: parameters
      expect(response).to have_http_status(:forbidden)
    end
    delete destroy_user_session_path
    login create(:user)
    get admin_network_index_path
    expect(response).to have_http_status(:forbidden)
  end
end
