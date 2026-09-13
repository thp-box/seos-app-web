require "rails_helper"
RSpec.describe "Footer et navigation légale", type: :system do
  it "affiche la home composée et ouvre les CGU depuis le footer sur mobile et ordinateur" do
    admin = create(:user, :super_admin)
    create(:content_version, author: admin, kind: "legal", slug: "cgu", title: "Conditions générales d’utilisation", body: "## Utiliser SEOS\n\nLes règles de la communauté.", published_at: Time.current)
    version = Studio.change!(actor: admin, name: "Accueil", settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette accueil") }
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit root_path
      expect(page).to have_css("[data-studio-block]", count: 11)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      page.execute_script("document.querySelector('.site-footer').scrollIntoView()")
      expect(page).to be_axe_clean.within(".site-footer").according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/footer-#{width}.png"))
      within(".site-footer") { click_link "Règles et CGU" }
      expect(page).to have_current_path(%r{/legal#legal-cgu$}, url: true)
      expect(page).to have_css("h2", text: "Conditions générales d’utilisation")
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      page.save_screenshot(Rails.root.join("tmp/screenshots/legal-#{width}.png"))
    end
  end
end
