require "rails_helper"

RSpec.describe "Présentation du voyage solidaire", type: :system do
  it "conserve le filtre et un affichage accessible sur mobile et ordinateur" do
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit volunteer_missions_path
      expect(page).to have_css("h1", text: "Voyage solidaire")
      fill_in "Filtrer par pays (code à deux lettres)", with: "FR"
      click_button "Filtrer les missions"
      expect(page).to have_current_path(volunteer_missions_path(country: "FR"))
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/travel-studio-#{width}.png"))
    end
  end
end
