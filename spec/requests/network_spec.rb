require "rails_helper"

RSpec.describe "Organisations, Voyage et partenaires", type: :request do
  let(:owner) { create(:profile).user }
  let(:organization) { organization_space(owner: owner) }
  let(:admin) { create(:user, :super_admin) }
  let(:candidate) { create(:profile).user }

  it "demande un espace et garde son identité privée jusque dans la revue motivée" do
    get account_organizations_path
    expect(response).to redirect_to(new_user_session_path)
    login owner
    post account_organizations_path, params: { organization: { name: "Le jardin", slug: "le-jardin", kind: "association", description: "Un jardin partagé", legal_name: "IDENTITE-PRIVEE", registration_number: "W1234", legal_email: "legal@example.test", status: "verified" } }
    expect(response).to have_http_status(:see_other)
    record = Organization.last
    expect(record).to be_pending
    get account_organization_path(record)
    expect(response.body).to include("IDENTITE-PRIVEE")
    get association_path(record)
    expect(response).to have_http_status(:not_found)
    delete destroy_user_session_path
    login admin
    get admin_network_index_path
    expect(response.body).not_to include("IDENTITE-PRIVEE", "legal@example.test")
    post admin_network_index_path, params: { operation: "reveal", record_id: record.id, reason: "Contrôle des documents" }
    expect(response.body).to include("IDENTITE-PRIVEE")
    post admin_network_index_path, params: { operation: "review", record_id: record.id, status: "verified", reason: "Documents vérifiés" }
    expect(response).to have_http_status(:see_other)
    get associations_path
    expect(response.body).to include("Le jardin")
    get association_path(record)
    expect(response.body).not_to include("IDENTITE-PRIVEE", "W1234", "legal@example.test")
    expect(response.body).to include("Organisation vérifiée")
  end

  it "retourne à l’invitation après connexion et limite un éditeur aux contenus de son équipe" do
    token = OrganizationWorkflow.invite!(organization: organization, actor: owner, email: candidate.email, role: "editor")
    get organization_invitation_path(invitation_token: token)
    expect(response).to redirect_to(new_user_session_path)
    expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
    login candidate
    expect(response).to redirect_to(organization_invitation_path)
    get organization_invitation_path
    expect(response.body).to include(organization.name)
    post organization_invitation_path
    expect(response).to redirect_to(account_organization_path(organization))
    get account_organization_path(organization)
    expect(response.body).not_to include("E-mail légal", "Inviter dans l’équipe", organization.legal_email)
    patch account_organization_path(organization), params: { operation: "profile", organization: { legal_name: "Vol" } }
    expect(response).to have_http_status(:forbidden)
    patch account_organization_path(organization), params: { operation: "invite", email: owner.email, role: "manager" }
    expect(response).to have_http_status(:forbidden)
    get account_organization_path(organization_space)
    expect(response).to have_http_status(:forbidden)
    get organization_invitation_path(invitation_token: token)
    expect(response).to have_http_status(:unprocessable_content)
    get admin_network_index_path
    expect(response).to have_http_status(:forbidden)
  end

  it "prépare une mission, publie exclusivement comme super-admin et protège les candidatures" do
    login owner
    patch account_organization_path(organization), params: { operation: "mission", mission: mission_attributes.merge(status: "published", daily_contribution_points: 100001) }
    expect(response).to have_http_status(:unprocessable_content)
    patch account_organization_path(organization), params: { operation: "mission", mission: mission_attributes }
    expect(response).to have_http_status(:see_other)
    mission = VolunteerMission.last
    get volunteer_mission_path(mission)
    expect(response).to have_http_status(:not_found)
    patch account_organization_path(organization), params: { operation: "mission_transition", record_id: mission.id, status: "pending_review", reason: "Prête" }
    expect(response).to have_http_status(:see_other)
    delete destroy_user_session_path
    login admin
    post admin_network_index_path, params: { operation: "mission_transition", record_id: mission.id, status: "published", reason: "Conditions contrôlées" }
    expect(response).to have_http_status(:see_other)
    get volunteer_missions_path(country: "FR")
    expect(response.body).to include("Jardin solidaire")
    get volunteer_mission_path(mission)
    expect(response.body).not_to include(mission.private_address, organization.legal_email)
    delete destroy_user_session_path
    login candidate
    post account_mission_applications_path, params: { mission_slug: mission.slug, message: "MOTIVATION-PRIVEE", starts_on: Date.current + 3, ends_on: Date.current + 7 }
    expect(response).to have_http_status(:see_other)
    application = MissionApplication.last
    get account_mission_application_path(application)
    expect(response.body).not_to include(mission.private_address)
    patch account_mission_application_path(application), params: { operation: "message", body: "Question privée", delivery_key: "one" }
    expect(response).to have_http_status(:see_other)
    delete destroy_user_session_path
    login owner
    get account_mission_applications_path
    expect(response.body).to include(mission.title)
    get account_mission_application_path(application)
    expect(response.body).to include("MOTIVATION-PRIVEE", "Question privée")
    patch account_mission_application_path(application), params: { operation: "decision", status: "accepted", reason: "Dates confirmées" }
    expect(response).to have_http_status(:see_other)
    get account_mission_application_path(application)
    expect(response.body).to include(mission.private_address)
    delete destroy_user_session_path
    login create(:user)
    get account_mission_application_path(application)
    expect(response).to have_http_status(:forbidden)
  end

  it "publie un partenariat sans transmettre de données privées ni charger de traceur" do
    login owner
    patch account_organization_path(organization), params: { operation: "partnership", partnership: partnership_attributes }
    expect(response).to have_http_status(:see_other)
    record = Partnership.last
    get partnership_path(record)
    expect(response).to have_http_status(:not_found)
    patch account_organization_path(organization), params: { operation: "partnership_transition", record_id: record.id, status: "pending_review", reason: "Proposition" }
    delete destroy_user_session_path
    login admin
    get admin_network_index_path
    expect(response).to have_http_status(:ok)
    post admin_network_index_path, params: { operation: "partnership_transition", record_id: record.id, status: "published", reason: "Accord vérifié" }
    expect(response).to have_http_status(:see_other)
    get partnerships_path
    expect(response.body).to include("Entraide ensemble")
    get partnership_path(record)
    expect(response.body).to include('rel="external noopener noreferrer"')
    expect(response.body).not_to include(organization.legal_email, owner.email, "iframe")
    post admin_network_index_path, params: { operation: "flag", key: "partnerships_enabled", enabled: "0", reason: "Pause" }
    get partnerships_path
    expect(response).to have_http_status(:not_found)
    post admin_network_index_path, params: { operation: "flag", key: "voyage_enabled", enabled: "0", reason: "Pause" }
    get volunteer_missions_path
    expect(response).to have_http_status(:not_found)
    get account_organizations_path
    expect(response.body).not_to include('href="/voyage-solidaire"', 'href="/partenaires"')
  end
end
