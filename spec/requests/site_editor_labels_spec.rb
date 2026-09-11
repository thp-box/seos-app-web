require "rails_helper"
RSpec.describe "Champs compréhensibles du Studio", type: :request do
  let(:admin) { create(:user, :super_admin) }

  it "présente chaque modèle avec des rubriques et des aides reliées aux champs" do
    login admin
    blocks = SiteDesign.reference.fetch("sections").keys.map { |key| { "id" => key, "template" => key, "values" => {} } }
    version = Studio.change!(actor: admin, name: "Modèles", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => blocks } } } })
    blocks.each do |block|
      get edit_admin_site_path(version, page: "home", section: block["id"])
      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      expect(doc.css(".editor-field-group[open]").size).to eq(1)
      doc.css(".editor-field-group .control").each do |input|
        expect(doc.at_css("label[for='#{input['id']}']").text).to match(/[[:alpha:]]/)
        expect(doc.at_css("##{input['aria-describedby']}").text).to be_present
      end
    end
  end

  it "conserve les symboles et valeurs existantes même lorsqu’ils ne sont plus proposés comme champs" do
    login admin
    block = { "id" => "hero", "template" => "home-0", "values" => { "text-6" => "⌕", "text-5" => "Notre présentation", "text-4" => "ensemble" } }
    version = Studio.change!(actor: admin, name: "Accueil", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ block ] } } } })
    get edit_admin_site_path(version, section: "hero")
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css("[name='values[text-6]']")).to be_nil
    expect(doc.at_css("label[for='hero-text-4']").text).to eq("Mots du titre en couleur")
    patch admin_site_path(version), params: { operation: "page", page: "home", block_id: "hero", block_action: "save", values: { "text-4" => "la solidarité" } }
    expect(response).to have_http_status(:see_other)
    saved = StudioVersion.last.site.dig("pages", "home", "blocks", 0, "values")
    expect(saved).to include("text-6" => "⌕", "text-5" => "Notre présentation", "text-4" => "la solidarité")
    expect(version.reload.site.dig("pages", "home", "blocks", 0, "values", "text-4")).to eq("ensemble")
  end
end
