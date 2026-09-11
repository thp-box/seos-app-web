require "rails_helper"

RSpec.describe "Sidebar du compte", type: :system do
  %i[member admin super_admin].each do |role|
    it "regroupe les liens et ferme la catégorie précédente pour #{role}" do
      user = create(:user, role: role)
      visit new_user_session_path
      fill_in "E-mail", with: user.email
      fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
      click_button "Se connecter"
      expect(page).to have_current_path(account_root_path)

      [ 375, 1440 ].each do |width|
        resize_viewport(width)
        if width == 375
          find(".account-sidebar .mobile-workspace-navigation > summary").send_keys(:enter)
        end
        within(".account-sidebar") do
          expect(page).to have_link("Mon compte")
          expect(page).not_to have_link("Mes sessions", visible: true)
          find("summary", text: /\AAnnonces et échanges\z/).send_keys(:enter)
          expect(page).to have_link("Mes annonces")
          find("summary", text: /\ASécurité et confidentialité\z/).click
          expect(page).to have_link("Mes sessions")
          expect(page).not_to have_link("Mes annonces", visible: true)
          expect(page).to have_css(".admin-nav-group[open]", count: 1)
          find("summary", text: /\ASécurité et confidentialité\z/).send_keys(:enter)
          expect(page).not_to have_css(".admin-nav-group[open]")
        end
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
        page.save_screenshot(Rails.root.join("tmp/screenshots/account-navigation-#{role}-#{width}.png"))
      end

      within(".account-sidebar .desktop-workspace-navigation") do
        find("summary", text: /\AAnnonces et échanges\z/).click
        click_link "Mes annonces"
      end
      expect(page).to have_current_path(account_listings_path)
      within(".account-sidebar .desktop-workspace-navigation") do
        expect(page).to have_css('.admin-nav-group[open] a[aria-current="page"]', text: "Mes annonces")
        click_link "Mes annonces"
      end
      visit new_account_listing_path
      expect(page).to have_css('.account-sidebar .desktop-workspace-navigation .admin-nav-group[open] a[aria-current="page"]', text: "Mes annonces")
    end
  end
end
