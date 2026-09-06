require "rails_helper"

RSpec.describe "Droits et médias des organisations", type: :request do
  let(:owner) { create(:profile).user }
  let(:organization) { organization_space(owner: owner) }
  let(:admin) { create(:user, :super_admin) }
  def photo
    path = Rails.root.join("tmp/network-photo.png")
    Vips::Image.black(20, 20).pngsave(path.to_s)
    Rack::Test::UploadedFile.new(path, "image/png")
  end

  it "réserve les invitations et la gestion d’équipe, permet une récupération auditée" do
    organization
    login owner
    get account_organizations_path
    expect(response.body).to include(organization.name)
    get account_organization_path(organization)
    expect(response).to have_http_status(:ok)
    patch account_organization_path(organization), params: { operation: "invite", email: "invite@example.test", role: "editor" }
    expect(response.body).to include("Invitation prête", "invitation_token=")
    invitation = OrganizationInvitation.last
    get account_organization_path(organization)
    expect(response.body).to include("Révoquer cette invitation")
    patch account_organization_path(organization), params: { operation: "revoke_invitation", record_id: invitation.id }
    expect(invitation.reload.available?).to be(false)
    membership = organization.organization_memberships.find_by!(user: owner)
    patch account_organization_path(organization), params: { operation: "membership", record_id: membership.id, role: "editor", status: "active" }
    expect(response).to have_http_status(:unprocessable_content)
    patch account_organization_path(organization), params: { operation: "unknown" }
    expect(response).to have_http_status(:unprocessable_content)
    delete destroy_user_session_path
    login admin
    post admin_network_index_path, params: { operation: "recover_owner", record_id: organization.id, user_id: admin.id, reason: "Continuité de gestion" }
    expect(response).to have_http_status(:see_other)
    patch account_organization_path(organization), params: { operation: "membership", record_id: membership.id, role: "editor", status: "active" }
    expect(response).to have_http_status(:see_other)
    post admin_network_index_path, params: { operation: "unknown" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_network_index_path, params: { operation: "flag", key: "financial_support_enabled", enabled: "1", reason: "Non" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "protège les logos et photos des brouillons, et coupe les médias après suspension" do
    login owner
    patch account_organization_path(organization), params: { operation: "profile", organization: { description: "Notre projet" }, logo: photo }
    expect(response).to have_http_status(:see_other)
    organization.reload
    get media_path(organization.logo.attachment)
    expect(response.media_type).to eq("image/jpeg")
    patch account_organization_path(organization), params: { operation: "mission", mission: mission_attributes, photos: [ photo ] }
    expect(response).to have_http_status(:see_other)
    mission = VolunteerMission.last
    patch account_organization_path(organization), params: { operation: "partnership", partnership: partnership_attributes, logo: photo }
    record = Partnership.last
    expect(record.logo).to be_attached
    get account_organization_path(organization, mission_id: mission.id, partnership_id: record.id)
    expect(response.body).to include("Aperçu de la mission", "Aperçu du partenariat")
    [ mission.photos.first, record.logo.attachment ].each do |attachment|
      get media_path(attachment)
      expect(response).to have_http_status(:ok)
    end
    delete destroy_user_session_path
    [ organization.logo.attachment, mission.photos.first, record.logo.attachment ].each do |attachment|
      get media_path(attachment)
      expect(response).to have_http_status(:not_found)
    end
    OrganizationWorkflow.review!(organization: organization, actor: admin, status: "verified", reason: "Profil vérifié")
    Missions.transition!(mission: mission, actor: admin, status: "published", reason: "Mission vérifiée")
    PartnershipWorkflow.transition!(record: record, actor: admin, status: "published", reason: "Accord vérifié")
    [ organization.logo.attachment, mission.photos.first, record.logo.attachment ].each do |attachment|
      get media_path(attachment)
      expect(response).to have_http_status(:ok)
    end
    organization.update!(status: "suspended")
    [ organization.logo.attachment, mission.photos.first, record.logo.attachment ].each do |attachment|
      get media_path(attachment)
      expect(response).to have_http_status(:not_found)
    end
  end

  it "limite les délégations administratives et crée les annonces monde au nom d’une association" do
    staff = create(:user, :admin)
    grant(staff, "missions.manage")
    mission = world_mission(organization: organization)
    login staff
    post admin_network_index_path, params: { operation: "mission_transition", record_id: mission.id, status: "published", reason: "Non" }
    expect(response).to have_http_status(:forbidden)
    post admin_network_index_path, params: { operation: "reveal", record_id: organization.id, reason: "Non" }
    expect(response).to have_http_status(:forbidden)
    post admin_network_index_path, params: { operation: "flag", key: "voyage_enabled", enabled: "0", reason: "Non" }
    expect(response).to have_http_status(:forbidden)
    post admin_network_index_path, params: { operation: "mission_transition", record_id: mission.id, status: "paused", reason: "Modération" }
    expect(response).to have_http_status(:see_other)
    delete destroy_user_session_path
    login admin
    post admin_network_index_path, params: { operation: "mission", organization_id: organization.id, mission: mission_attributes.merge(title: "Mission monde créée par l’équipe") }
    expect(response).to have_http_status(:see_other)
    post admin_network_index_path, params: { operation: "partnership", organization_id: organization.id, partnership: partnership_attributes.merge(kind: "institutional", position: 4) }
    expect(response).to have_http_status(:see_other)
    record = Partnership.last
    post admin_network_index_path, params: { operation: "partnership", record_id: record.id, partnership: { public_title: "Nouveau titre", position: 2 } }
    expect(response).to have_http_status(:see_other)
    get admin_network_index_path
    expect(response.body).to include("Mission monde créée par l’équipe", "Nouveau titre")
  end
end
