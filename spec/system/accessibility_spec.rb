require "rails_helper"
RSpec.describe "Accessibilité du socle", :"F-002", :"F-007", :accessibility, type: :system do
  it "respecte les règles automatiques WCAG 2.2 AA sur accueil et authentification" do
    [ root_path, new_user_session_path, new_user_registration_path, new_user_password_path, new_user_confirmation_path ].each do |path|
      visit path
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
    end
  end

  it "respecte les règles automatiques sur l'administration" do
    user = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ account_root_path, admin_root_path, admin_users_path, admin_audit_logs_path, super_admin_administrators_path ].each do |path|
      visit path
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
    end
  end
end
