require "rails_helper"

RSpec.describe "Voyage solidaire dans le Studio", type: :request do
  it "publie les textes et garde un aperçu privé avant publication" do
    admin = create(:user, :super_admin)
    login admin
    source = Studio.change!(actor: admin, settings: {}, name: "Voyage")
    get visual_admin_site_path(source, page: "voyage-solidaire")
    expect(response).to have_http_status(:ok)
    get preview_admin_studio_path(source, page: "voyage-solidaire", canvas: "1")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Filtrer les missions")
    patch admin_site_path(source), params: { operation: "page", page: "voyage-solidaire", block_id: "travel-list", block_action: "save", values: { "text-0" => "Votre pays", "text-2" => "De nouvelles missions arrivent bientôt." } }
    expect(response).to have_http_status(:see_other)
    version = StudioVersion.last
    get volunteer_missions_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("De nouvelles missions arrivent bientôt.")
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette du voyage") }
    get volunteer_missions_path(country: "FR")
    expect(response.body).to include("De nouvelles missions arrivent bientôt.", "Votre pays", 'value="FR"')
    expect(source.reload.site).to eq({})
  end

  it "réserve les modifications au super admin" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, settings: {}, name: "Voyage")
    login create(:user)
    get visual_admin_site_path(version, page: "voyage-solidaire")
    expect(response).to have_http_status(:forbidden)
  end
end
