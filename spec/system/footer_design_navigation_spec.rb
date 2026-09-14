require "rails_helper"
RSpec.describe "Design après navigation depuis le footer", type: :system do
  it "conserve les fonds et raccords pendant les allers-retours entre accueil et voyage" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Navigation", settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette") }
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit root_path
      within("footer") { click_link "Voyage solidaire" }
      expect(page).to have_current_path(volunteer_missions_path)
      expect(page).to have_css('[data-studio-block="travel-intro"]')
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#site-section-travel-intro > section')).backgroundColor")).to eq("rgb(0, 73, 97)")
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#site-section-travel-intro')).getPropertyValue('--next-bg').trim()")).not_to be_empty
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#site-section-travel-intro .page-hero-organic-cut path:last-child')).fill")).to eq("rgb(251, 250, 244)")
      page.execute_script("document.querySelector('#site-section-travel-intro').scrollIntoView({block:'start'})")
      page.save_screenshot(Rails.root.join("tmp/screenshots/footer-travel-#{width}.png"))
      within("footer") { click_link "Le concept" }
      expect(page).to have_css("#presentation video")
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#site-section-home-4 > section')).backgroundColor")).to eq("rgb(0, 73, 97)")
      within("footer") { click_link "Chaîne d’entraide" }
      expect(page).to have_css(".chain-example")
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#site-section-home-4 > section')).backgroundColor")).to eq("rgb(0, 73, 97)")
      within("footer") { click_link "Voyage solidaire" }
      expect(page).to have_current_path(volunteer_missions_path)
      page.go_back
      expect(page).to have_css(".chain-example")
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#site-section-home-4 > section')).backgroundColor")).to eq("rgb(0, 73, 97)")
      page.save_screenshot(Rails.root.join("tmp/screenshots/footer-navigation-#{width}.png"))
    end
  end
end
