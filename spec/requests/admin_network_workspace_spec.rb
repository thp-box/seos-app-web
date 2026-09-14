require "rails_helper"

RSpec.describe "Dossiers administratifs paginés", type: :request do
  it "priorise les demandes et filtre les grandes listes sans afficher tous les formulaires" do
    create_list(:organization, 21, status: "verified", request_kind: "community_mission")
    pending = create(:organization, name: "Projet prioritaire", status: "pending", request_kind: "partnership", updated_at: 1.month.ago)
    login create(:user, :admin)
    get admin_network_index_path
    document = Nokogiri::HTML(response.body)
    expect(document.css(".network-dossier").size).to eq(20)
    expect(document.at_css(".network-dossier").text).to include(pending.name)
    expect(response.body).not_to include("Enregistrer la décision")
    get admin_network_index_path(page: 2)
    expect(Nokogiri::HTML(response.body).css(".network-dossier").size).to eq(2)
    get admin_network_index_path(request_kind: "partnership", status: "pending", q: "prioritaire")
    expect(Nokogiri::HTML(response.body).css(".network-dossier").size).to eq(1)
    get admin_network_path(pending.id, section: "organizations")
    expect(response.body).to include("Votre décision", pending.name)
    get admin_network_path(pending.id, section: "missions")
    expect(response).to have_http_status(:forbidden)
    get admin_network_path(pending.id, section: "settings")
    expect(response).to have_http_status(:forbidden)
  end
end
