require "rails_helper"
RSpec.describe "Destinations du footer légal", type: :system do
  it "ouvre chaque destination et affiche les exemples complets de la maquette" do
    resize_viewport(1440)
    visit root_path
    { "Sécurité" => "legal-securite", "Règles et CGU" => "legal-cgu", "Centre légal" => "legal-introduction" }.each do |label, id|
      within("footer") { click_link label }
      expect(page).to have_current_path(%r{/legal##{id}$}, url: true)
      expect(page).to have_css("##{id}")
      page.driver.browser.action.pause(duration: 0.3).perform
      top = page.evaluate_script("document.getElementById('#{id}').getBoundingClientRect().top")
      expect(top).to be_between(0, 180)
    end
    expect(page).to have_css("#legal-cgu ul li", count: 3)
    expect(page).to have_css("#legal-confidentialite table", count: 2)
    expect(page).to have_css("#legal-confidentialite table tbody tr", count: 9)
    expect(page).to have_content("Profils vérifiés")
    resize_viewport(375)
    within("footer") { click_link "Confidentialité & RGPD" }
    expect(page).to have_current_path(%r{/legal#legal-confidentialite$}, url: true)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
  end
end
