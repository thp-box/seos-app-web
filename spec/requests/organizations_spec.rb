require "rails_helper"
RSpec.describe "Isolement des organisations", :"F-004", type: :request do
  it "montre seulement les organisations accessibles et masque les coordonnées de l'équipe" do
    membership = create(:organization_membership, role: :owner)
    foreign = create(:organization)
    login(membership.user)
    get account_root_path
    expect(response.body).to include(membership.organization.name)
    expect(response.body).not_to include(foreign.name)
    get organization_dashboard_path(organization_slug: membership.organization.slug)
    expect(response).to have_http_status(:ok)
    get organization_team_path(organization_slug: membership.organization.slug)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(membership.user.email)
    get organization_dashboard_path(organization_slug: foreign.slug)
    expect(response).to have_http_status(:forbidden)
  end

  it "refuse l'équipe à un éditeur, même par URL directe" do
    membership = create(:organization_membership)
    login(membership.user)
    get organization_dashboard_path(organization_slug: membership.organization.slug)
    expect(response.body).not_to include("Voir l’équipe")
    get organization_team_path(organization_slug: membership.organization.slug)
    expect(response).to have_http_status(:forbidden)
  end
end
