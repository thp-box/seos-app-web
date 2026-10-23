require "rails_helper"

RSpec.describe "Demandes d’association", type: :request do
  it "crée uniquement un espace associatif même si le client envoie un ancien type" do
    login create(:profile).user
    post account_organizations_path, params: { organization: { name: "Atelier local", slug: "atelier-local", kind: "micro_company", request_kind: "partnership", description: "Un atelier de proximité" } }
    expect(response).to have_http_status(:see_other)
    expect(Organization.find_by!(slug: "atelier-local")).to have_attributes(kind: "association", request_kind: "community_mission", status: "pending")
  end

  it "ne présente plus de choix de partenariat aux membres" do
    login create(:profile).user
    get account_organizations_path
    expect(response.body).to include("Présenter mon association")
    expect(response.body).not_to include("Proposer un partenariat", "micro_company", "request_kind")
  end
end
