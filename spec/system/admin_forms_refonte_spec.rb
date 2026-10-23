require "rails_helper"

RSpec.describe "Formulaires de la super-administration", type: :system do
  it "reste lisible et accessible sur les pages partenaires et quêtes" do
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)

    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      [ edit_admin_partnership_page_path, admin_community_index_path(tab: "quests"), admin_community_index_path(tab: "chains") ].each do |path|
        visit path
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true), path
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      end
    end
  end
end
