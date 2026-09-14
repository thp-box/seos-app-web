require "rails_helper"
RSpec.describe "Footer et accueil maquette", type: :request do
  it "affiche les quatre rubriques, les CGU et le centre légal" do
    get root_path
    doc = Nokogiri::HTML(response.body)
    expect(doc.css(".site-footer nav").size).to eq(4)
    expect(doc.at_css('.site-footer a[href="/legal#legal-cgu"]').text).to eq("Règles et CGU")
    expect(doc.at_css('.site-footer a[href="/legal#legal-mentions-legales"]')).to be_present
    get legal_center_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Documents juridiques")
  end

  it "affiche le document publié avec une navigation légale active" do
    create(:content_version, kind: "legal", slug: "cgu", title: "Conditions générales", body: "Texte publié", published_at: Time.current)
    get legal_center_path(onglet: "cgu")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Texte publié")
    expect(Nokogiri::HTML(response.body).at_css('.legal-sidebar a[href="#legal-cgu"]').text).to eq("Conditions d’utilisation")
  end

  it "compose les onze sections dans l’ordre et conserve leurs modèles éditables" do
    document = SiteDesign.home_page
    expect(document["blocks"].map { |block| block["template"] }).to eq(11.times.map { |i| "home-#{i}" })
    expect(SiteDesign.valid?({ "pages" => { "home" => document } })).to be(true)
    document["blocks"].each { |block| expect(SiteDesign.templates).to have_key(block["template"]) }
  end
end
