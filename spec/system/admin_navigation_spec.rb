require "rails_helper"

RSpec.describe "Sidebar de l’administration", type: :system do
  it "reste compacte, accessible et ouvre les bons outils" do
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    visit admin_root_path

    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit admin_root_path
      if width <= 1040 && page.has_css?(".admin-sidebar .mobile-workspace-navigation > summary", visible: :all)
        find(".admin-sidebar .mobile-workspace-navigation > summary", visible: :all).click
      end
      within(".admin-sidebar") do
        expect(page).to have_content("Essentiel")
        expect(page).to have_content("Communauté")
        expect(page).to have_content("Outils")
        expect(page).not_to have_content("Kit UI/UX")
        expect(page).not_to have_content("Pages et sections")
      end
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
    end

    within(".desktop-workspace-navigation") do
      find("summary", text: "Outils").click
      click_link "Éditeur visuel"
    end
    expect(page).to have_css("h1", text: "Éditeur visuel")
    visit admin_users_path
    expect(page).to have_css('.desktop-workspace-navigation a[aria-current="page"]', text: "Membres")
  end
end
