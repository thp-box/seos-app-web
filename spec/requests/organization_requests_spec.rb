require "rails_helper"
RSpec.describe "Demandes d’organisation", type: :request do
  it "conserve le projet et accepte les micro-entreprises pour les partenariats" do
    owner = create(:profile).user
    login owner
    attributes = { name: "Atelier local", slug: "atelier-local", kind: "micro_company", request_kind: "partnership", description: "Un atelier de proximité" }
    post account_organizations_path, params: { organization: attributes }
    expect(response).to have_http_status(:see_other)
    record = Organization.find_by!(slug: "atelier-local")
    expect(record).to have_attributes(kind: "micro_company", request_kind: "partnership", status: "pending", published_at: nil)
    delete destroy_user_session_path
    login create(:user, :super_admin)
    get admin_network_index_path
    expect(response.body).to include("Micro-entreprise", "Demande : Partenariat")
  end

  it "refuse une mission communautaire portée par une entreprise même sans JavaScript" do
    login create(:profile).user
    expect {
      post account_organizations_path, params: { organization: { name: "Atelier", slug: "atelier", kind: "company", request_kind: "community_mission" } }
    }.not_to change(Organization, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end
end
