require "rails_helper"

RSpec.describe "Suppression des pages du Studio", type: :request do
  it "supprime le voyage après publication, retire ses liens et préserve les sauvegardes" do
    admin = create(:user, :super_admin)
    login admin
    source = Studio.change!(actor: admin, settings: {}, name: "Site")
    patch admin_site_path(source), params: { operation: "delete_page", page: "voyage-solidaire" }
    expect(response).to have_http_status(:see_other)
    version = StudioVersion.last
    expect(version.available_pages).not_to include("voyage-solidaire")
    get volunteer_missions_path
    expect(response).to have_http_status(:ok)
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Suppression demandée") }
    get volunteer_missions_path
    expect(response).to have_http_status(:not_found)
    get root_path
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).css('header a[href="/voyage-solidaire"]')).to be_empty
    expect(source.reload.deleted_pages).to be_empty
  end

  it "interdit la suppression des pages protégées même dans un document forgé" do
    %w[home accueil annonces listings].each do |slug|
      expect(SiteDesign.valid?({ "deleted_pages" => [ slug ] })).to be(false)
    end
  end

  it "supprime aussi les pages éditoriales et personnalisées sans retour au contenu initial" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, settings: { "site" => { "deleted_pages" => %w[communaute don ma-page] } }, name: "Suppressions")
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Suppression demandée") }
    [ community_path, explanation_path("don"), site_page_path("ma-page") ].each do |path|
      get path
      expect(response).to have_http_status(:not_found)
    end
  end
end
