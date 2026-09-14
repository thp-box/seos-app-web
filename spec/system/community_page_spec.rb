require "rails_helper"

RSpec.describe "Présentation de la communauté", type: :system do
  it "reste lisible sur téléphone et ordinateur" do
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit community_path
      expect(page).to have_content("Les associations ont leur place ici.")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/community-#{width}.png"))
    end
  end
end
