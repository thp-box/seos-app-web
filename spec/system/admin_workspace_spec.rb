require "rails_helper"

RSpec.describe "Présentation de l’administration", type: :system do
  it "permet d’examiner les dossiers dans une interface adaptée aux deux écrans" do
    organization = organization_space(status: "pending", published_at: nil)
    Partnership.create!({ organization: organization }.merge(partnership_attributes))
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit admin_network_index_path
      expect(page).to have_css(".network-dossier", count: 1)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/admin-workspace-list-#{width}.png"))
      find(".network-open").click
      expect(page).to have_content("Votre décision")
      expect(page).not_to have_content(organization.legal_email)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      page.save_screenshot(Rails.root.join("tmp/screenshots/admin-workspace-detail-#{width}.png"))
    end
    select "Vérifiée", from: "Décision"
    fill_in "Motif de décision", with: "Projet examiné et validé"
    click_button "Enregistrer la décision"
    expect(page).to have_css(".network-detail-heading .network-badge", text: "Vérifiée")
    expect(organization.reload).to be_verified
    [ admin_users_path, admin_operations_path, admin_points_path, admin_trust_index_path, admin_audit_logs_path ].each_with_index do |path, index|
      [ 1440, 375 ].each do |width|
        resize_viewport(width)
        visit path
        expect(page).to have_css(".admin-console-heading h1")
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
        page.save_screenshot(Rails.root.join("tmp/screenshots/admin-section-#{index}-#{width}.png"))
      end
    end
  end
end
