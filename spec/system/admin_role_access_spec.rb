require "rails_helper"

RSpec.describe "Panneau des annonces pour un admin", type: :system do
  it "donne un accès visible aux annonces et retire la gestion du site" do
    admin = create(:user, :admin)
    create(:admin_permission_grant, user: admin, permission: "content.manage")
    create(:admin_permission_grant, user: admin, permission: "categories.manage")
    listing = create(:listing, title: "Annonce à examiner")
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit admin_root_path
      expect(page).to have_link("Gérer les annonces")
      expect(page).not_to have_content("Gestion du site")
      expect(page).not_to have_link("Propositions éditoriales", visible: :all)
      click_link "Gérer les annonces"
      expect(page).to have_content("Annonce à examiner")
      expect(page).to have_link("Examiner")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/ordinary-admin-listings-#{width}.png"))
    end
    click_link "Examiner"
    select "Suspendre la diffusion", from: "Action à appliquer"
    fill_in "Motif de modération", with: "Abus constaté"
    click_button "Appliquer et notifier le membre"
    expect(page).to have_content(/En pause/i)
    expect(listing.reload.moderation_hold?).to be(true)
  end
end
