require "rails_helper"
RSpec.describe "Présentation et pages d’échange", type: :request do
  let(:admin) { create(:user, :super_admin) }
  it "remplace l’ancienne explication par la vidéo et compose les trois pages" do
    get explanation_path("fonctionnement")
    expect(response).to redirect_to(root_path(anchor: "presentation"))
    %w[don echange points].each do |slug|
      get explanation_path(slug)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("page-hero", "data-image")
    end
  end
  it "enregistre des diapositives et la vidéo, sans autoriser de source active" do
    login admin
    version = Studio.change!(actor: admin, name: "Présentation", settings: {})
    document = { "site" => { "pages" => { "home" => SiteDesign.home_page } } }
    blocks = document["site"]["pages"]["home"]["blocks"]
    slides = JSON.parse(SiteDesign.templates["home-0"]["fields"]["slides"]["default"])
    slides.first["label"] = "Un jardin partagé"
    blocks.first["values"]["slides"] = slides.to_json
    blocks[5]["values"]["video-url"] = "https://media.example.org/presentation.mp4"
    post visual_save_admin_site_path(version), params: { document: document.to_json, digest: version.digest }
    expect(response).to have_http_status(:ok)
    saved = StudioVersion.last
    %w[validate publish].each { |action| Studio.transition!(version: saved, actor: admin, action: action, reason: "Présentation") }
    get root_path
    dom = Nokogiri::HTML(response.body)
    expect(dom.at_css('#presentation video')["src"]).to eq("https://media.example.org/presentation.mp4")
    expect(dom.at_css('#presentation .caption')).to be_nil
    expect(dom.at_css('.hero [data-link="link-1"]')["href"]).to eq("/#presentation")
    expect(dom.css('.hero-slide').size).to eq(3)
    expect(dom.at_css('.hero-slide')["data-label"]).to eq("Un jardin partagé")
    blocks[5]["values"]["video-url"] = "javascript:alert(1)"
    expect(SiteDesign.valid?(document["site"])).to be(false)
    blocks[5]["values"]["video-url"] = ""
    slides.first["image"] = "https://untrusted.test/image.svg"
    blocks.first["values"]["slides"] = slides.to_json
    expect(SiteDesign.valid?(document["site"])).to be(false)
  end
end
