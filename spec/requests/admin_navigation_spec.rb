require "rails_helper"

RSpec.describe "Navigation d’administration", type: :request do
  def desktop_navigation
    Nokogiri::HTML(response.body).at_css(".desktop-workspace-navigation")
  end

  it "regroupe les tâches et ouvre uniquement l’éditeur visuel" do
    login create(:user, :super_admin)
    get admin_root_path
    navigation = desktop_navigation
    expect(navigation.css(".admin-nav-group > summary span:first-child").map(&:text)).to eq([ "Essentiel", "Communauté", "Outils" ])
    expect(navigation.text).to include("Quêtes & chaînes", "Éditeur visuel", "Page partenaires")
    expect(navigation.text).not_to include("Kit UI/UX", "Pages et sections", "Carte publique")
    expect(navigation.css("a").map { |link| link["href"] }.uniq.size).to eq(navigation.css("a").size)

    get admin_site_index_path
    expect(response).to have_http_status(:see_other)
    follow_redirect!
    expect(response.body).to include("Éditeur visuel")
  end

  it "masque les outils réservés au super-admin" do
    admin = create(:user, :admin)
    grant(admin, "users.read")
    login admin
    get admin_root_path
    expect(desktop_navigation.text).to include("Membres")
    expect(desktop_navigation.text).not_to include("Éditeur visuel", "Page partenaires", "Supervision", "Administrateurs")
    get admin_site_index_path
    expect(response).to have_http_status(:forbidden)
  end

  it "garde un seul lien actif sur les sous-pages" do
    login create(:user, :super_admin)
    get admin_workbench_index_path(kind: "signalements")
    active = desktop_navigation.css('a[aria-current="page"]')
    expect(active.map(&:text)).to eq([ "Signalements" ])
    expect(active.first.ancestors("details").first["open"]).not_to be_nil
  end
end
