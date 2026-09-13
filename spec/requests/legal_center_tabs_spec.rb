require "rails_helper"
RSpec.describe "Centre légal unifié", type: :request do
  let(:admin) { create(:user, :super_admin) }
  it "redirige les anciennes pages vers leur section et regroupe les liens du footer" do
    ContentVersion::LEGAL_SLUGS.each do |slug|
      get legal_path(slug)
      expect(response).to redirect_to(legal_center_path(anchor: "legal-#{slug}"))
    end
    get trust_explanation_path
    expect(response).to redirect_to(legal_center_path(anchor: "legal-securite"))
    get privacy_preferences_path
    expect(response).to have_http_status(:ok)
    get root_path
    doc = Nokogiri::HTML(response.body)
    %w[securite cgu confidentialite cookies mentions-legales].each do |tab|
      expect(doc.at_css("footer a[href='/legal#legal-#{tab}']")).to be_present
    end
  end
  it "affiche uniquement le contenu publié, toutes les sections et les réglages Studio" do
    create(:content_version, author: admin, kind: "legal", slug: "cgu", title: "CGU publiées", body: "## Nos règles\n\n**Important** : aucun HTML. <script>alert(1)</script>", published_at: Time.current)
    create(:content_version, author: admin, kind: "legal", slug: "cgu", version: 2, title: "Brouillon secret", body: "Ne pas publier")
    page = SiteDesign.default_page("legal")
    page["blocks"][0]["values"] = { "title" => "Nos engagements", "tab-cgu" => "Les règles", "security-title" => "Se rencontrer sereinement", "preferences-title" => "Vos choix sur SEOS" }
    version = Studio.change!(actor: admin, name: "Centre légal", settings: { "site" => { "pages" => { "legal" => page } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Publication du centre") }
    get legal_center_path(onglet: "cgu")
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("no-store")
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('.legal-sidebar a[href="#legal-cgu"]').text).to eq("Les règles")
    expect(doc.at_css('#legal-cgu h2').text).to eq("CGU publiées")
    expect(response.body).to include("Nos engagements", "Se rencontrer sereinement", "&lt;script&gt;")
    expect(response.body).not_to include("Brouillon secret")
    expect(doc.css(".legal-document").size).to eq(5)
    expect(doc.css(".legal-document[hidden]")).to be_empty
    get privacy_preferences_path, params: { popup: "1" }
    expect(response.body).to include("<dialog", "Vos choix sur SEOS")
    expect(response.headers["Cache-Control"]).to include("no-store")
    post privacy_preferences_path, params: { choice: "reject" }
    expect(response).to redirect_to(legal_center_path(anchor: "legal-cookies"))
    expect(CookieConsent.last.analytics).to be(false)
  end
end
