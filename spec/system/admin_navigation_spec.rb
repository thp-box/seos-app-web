require "rails_helper"
RSpec.describe "Sidebar de l’administration", type: :system do
  it "reste compacte, utilisable au clavier et ouvre le bon onglet" do
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit admin_root_path
    [ 375, 768, 1440 ].each do |width|
      resize_viewport(width)
      if width <= 1040
        disclosure = find(".admin-sidebar .mobile-workspace-navigation > summary")
        disclosure.send_keys(:enter) unless page.has_css?(".admin-sidebar .mobile-workspace-navigation[open]")
      end
      within(".admin-sidebar") do
        expect(page).to have_link("Pages et sections")
        expect(page).to have_link("Kit UI/UX")
        expect(page).not_to have_link("Administrateurs", visible: true)
        find("summary", text: /\ACommunauté\z/).send_keys(:enter)
        expect(page).to have_link("Membres")
        expect(page).not_to have_link("Kit UI/UX", visible: true)
        expect(page).to have_css(".admin-nav-group[open]", count: 1)
        find("summary", text: /\APersonnalisation\z/).click
        expect(page).to have_link("Kit UI/UX")
        expect(page).not_to have_link("Membres", visible: true)
        expect(page).to have_css(".admin-nav-group[open]", count: 1)
      end
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/admin-navigation-#{width}.png"))
    end
    within(".desktop-workspace-navigation") { click_link "Kit UI/UX" }
    expect(page).to have_css("h1", text: "Kit UI/UX")
    click_button "Modifier le kit UI/UX"
    expect(page).to have_button("Enregistrer l’apparence")
    version = StudioVersion.last
    within(".desktop-workspace-navigation") { click_link "Pages et sections" }
    expect(page).to have_current_path(edit_admin_site_path(version, area: "pages"))
    expect(page).to have_css("summary", text: "Ajouter une partie à la page")
    within(".desktop-workspace-navigation") do
      find("summary", text: "Communauté").send_keys(:enter)
      click_link "Membres"
    end
    expect(page).to have_current_path(admin_users_path)
    expect(page).to have_css('.desktop-workspace-navigation a[aria-current="page"]', text: "Membres")
  end
end
