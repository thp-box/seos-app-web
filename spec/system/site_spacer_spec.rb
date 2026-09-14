require "rails_helper"

RSpec.describe "Hauteur des sections vides", type: :system do
  it "applique les hauteurs publiées selon la largeur de l’écran" do
    admin = create(:user, :super_admin)
    content = SiteDesign.community_page
    content["blocks"] << { "id" => "space", "template" => "spacer", "values" => { "height" => "240", "mobile_height" => "64" } }
    version = Studio.change!(actor: admin, settings: { "site" => { "pages" => { "communaute" => content } } }, name: "Espaces")
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette des hauteurs") }
    { 375 => 64, 1440 => 240 }.each do |width, height|
      resize_viewport(width)
      visit community_path
      expect(page).to have_css(".site-spacer")
      expect(page.evaluate_script("document.querySelector('.site-spacer').getBoundingClientRect().height")).to eq(height)
      expect(page).not_to have_text("Section vide")
    end
  end
end
