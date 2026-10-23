require "rails_helper"

RSpec.describe "Gestion des demandes par un admin", type: :request do
  it "ouvre les demandes et permet leur examen sans permission individuelle" do
    admin = create(:user, :admin)
    organization = organization_space(status: "pending", published_at: nil, request_kind: "community_mission")
    login admin
    get admin_root_path
    expect(response.body).to include("Associations et missions", "Gérer les demandes")
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

  it "conserve les limites sur les données privées et les actions exceptionnelles" do
    admin = create(:user, :admin)
    organization = organization_space
    login admin
    [
      { operation: "reveal", record_id: organization.id, reason: "Tentative" },
      { operation: "recover_owner", record_id: organization.id, user_id: admin.id, reason: "Tentative" },
      { operation: "review", record_id: organization.id, status: "verified", kind: "company", reason: "Tentative" },
      { operation: "flag", key: "voyage_enabled", enabled: "1", reason: "Tentative" }
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
