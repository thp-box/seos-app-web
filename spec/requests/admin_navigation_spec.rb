require "rails_helper"
RSpec.describe "Navigation d’administration", type: :request do
  def desktop_navigation
    Nokogiri::HTML(response.body).at_css(".desktop-workspace-navigation")
  end

  it "regroupe les outils et distingue les deux accès de personnalisation" do
    login create(:user, :super_admin)
    get admin_root_path
    navigation = desktop_navigation
    expect(navigation.css(".admin-nav-group > summary span:first-child").map(&:text)).to eq([ "Personnalisation", "Communauté", "Annonces et échanges", "Confiance et finances", "Gestion du site", "Administration" ])
    personalization = navigation.css(".admin-nav-group").first
    expect(personalization.css("a").map(&:text)).to eq([ "Pages et sections", "Kit UI/UX" ])
    expect(navigation.css(".admin-nav-group[open]").size).to eq(1)
    expect(navigation.css("a").map { |a| a["href"] }.uniq.size).to eq(navigation.css("a").size)
    expect { get admin_site_index_path(area: "kit") }.not_to change(StudioVersion, :count)
    expect(response.body).to include('<h1>Kit UI/UX — Apparence du site</h1>', 'Modifier le kit UI/UX')
    expect(desktop_navigation.at_css('a[aria-current="page"]').text).to eq("Kit UI/UX")
    post admin_site_index_path, params: { name: "Kit", area: "kit" }
    version = StudioVersion.last
    expect(response).to redirect_to(edit_admin_site_path(version, area: "kit"))
    follow_redirect!
    expect(desktop_navigation.at_css('a[aria-current="page"]').text).to eq("Kit UI/UX")
    expect(desktop_navigation.at_css('a[href*="area=pages"]')["href"]).to include("/#{version.id}/edit")
    get edit_admin_site_path(version, area: "footer")
    expect(desktop_navigation.at_css('a[aria-current="page"]').text).to eq("Pages et sections")
  end

  it "masque la personnalisation et les catégories sans permission aux admins" do
    admin = create(:user, :admin)
    grant(admin, "users.read")
    login admin
    get admin_root_path
    expect(desktop_navigation.text).not_to include("Personnalisation", "Kit UI/UX", "Pages et sections", "Confiance et finances", "Gestion du site")
    expect(desktop_navigation.text).to include("Membres")
    get admin_users_path
    expect(desktop_navigation.at_css('a[aria-current="page"]').text).to eq("Membres")
    get admin_site_index_path(area: "kit")
    expect(response).to have_http_status(:forbidden)
    grant(admin, "studio.preview")
    get admin_studio_index_path
    expect(desktop_navigation.text).to include("Propositions éditoriales")
    expect(desktop_navigation.text).not_to include("Personnalisation")
  end

  it "ouvre la rubrique d’une sous-page en conservant son lien actif unique" do
    login create(:user, :super_admin)
    get admin_workbench_index_path(kind: "signalements")
    active = desktop_navigation.css('a[aria-current="page"]')
    expect(active.map(&:text)).to eq([ "Signalements" ])
    expect(active.first.ancestors("details").first["open"]).not_to be_nil
  end
end
