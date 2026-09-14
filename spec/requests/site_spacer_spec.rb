require "rails_helper"

RSpec.describe "Sections vides du Studio", type: :request do
  it "ajoute, dimensionne et publie un espace vide sans texte visible" do
    admin = create(:user, :super_admin)
    login admin
    source = Studio.change!(actor: admin, settings: {}, name: "Espaces")
    patch admin_site_path(source), params: { operation: "page", page: "communaute", template: "spacer" }
    expect(response).to have_http_status(:see_other)
    draft = StudioVersion.last
    block = draft.site.dig("pages", "communaute", "blocks").last
    get edit_admin_site_path(draft, page: "communaute", section: block["id"])
    expect(response.body).to include("Hauteur sur ordinateur (px)", "Hauteur sur téléphone (px)")
    get visual_admin_site_path(draft, page: "communaute")
    expect(response).to have_http_status(:ok)
    patch admin_site_path(draft), params: { operation: "page", page: "communaute", block_id: block["id"], block_action: "save", values: { height: "240", mobile_height: "64" } }
    expect(response).to have_http_status(:see_other)
    version = StudioVersion.last
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Vérifier les espacements") }
    get community_path
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css(".site-spacer").text).to eq("")
    expect(doc.css("style").text).to include("height:240px", "height:64px")
    expect(source.reload.site).to eq({})
  end

  it "refuse des dimensions invalides ou du CSS injecté" do
    block = { "id" => "space", "template" => "spacer", "values" => {} }
    expect(SiteDesign.valid_block?(block)).to be(true)
    %w[0 -1 1201 12.5 20px 20\;color:red].each do |value|
      expect(SiteDesign.valid_block?(block.merge("values" => { "height" => value }))).to be(false)
    end
  end
end
