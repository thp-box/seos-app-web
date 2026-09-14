require "rails_helper"

RSpec.describe "Page La communauté", type: :request do
  it "présente l’application et les associations sans dépendre d’une publication préalable" do
    get community_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Un coup de main, à votre façon.", "Les associations ont leur place ici.", "Participer autrement")
    expect(Nokogiri::HTML(response.body).at_css('a[href="/communaute"][aria-current="page"]')).to be_present
    expect(SiteDesign.valid?({ "pages" => { "communaute" => SiteDesign.default_page("communaute") } })).to be(true)
    expect(response.body).to include('href="/compte/organisations"')
  end

  it "adapte uniquement le lien historique sans modifier les versions enregistrées" do
    legacy = { "links" => [ { "label" => "L’association", "url" => "/associations" }, { "label" => "Notre collectif", "url" => "/associations" } ] }
    chrome = SiteDesign.chrome("header", legacy)
    expect(chrome["links"].first).to eq({ "label" => "La communauté", "url" => "/communaute" })
    expect(chrome["links"].last).to eq(legacy["links"].last)
    expect(legacy["links"].first["label"]).to eq("L’association")
  end

  it "permet au super admin de prévisualiser, modifier et publier la page" do
    admin = create(:user, :super_admin)
    login admin
    source = Studio.change!(actor: admin, settings: {}, name: "Communauté")
    get visual_admin_site_path(source, page: "communaute")
    expect(response).to have_http_status(:ok)
    get preview_admin_studio_path(source, page: "communaute", canvas: "1")
    expect(response).to have_http_status(:ok)
    patch admin_site_path(source), params: { operation: "page", page: "communaute", block_id: "community-associations", block_action: "save", values: { "text-1" => "Ensemble avec les associations" } }
    expect(response).to have_http_status(:see_other)
    version = StudioVersion.last
    get community_path
    expect(response.body).not_to include("Ensemble avec les associations")
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Publication de la communauté") }
    get community_path
    expect(response.body).to include("Ensemble avec les associations")
    expect(source.reload.site).to eq({})
  end
end
