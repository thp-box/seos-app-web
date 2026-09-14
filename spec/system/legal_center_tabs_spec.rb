require "rails_helper"
RSpec.describe "Édition du centre légal", type: :system do
  it "permet au super admin de modifier la présentation dans le Studio sans publication immédiate" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Centre à personnaliser", settings: {})
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit visual_admin_site_path(version, page: "legal")
    within_frame(find("iframe")) { find('.legal-center h1 [data-field="title"]').click }
    within('.visual-inspector') { fill_in "Titre du centre", with: "Nos règles et vos choix" }
    within_frame(find("iframe")) { expect(page).to have_css('h1', text: "Nos règles et vos choix") }
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Copie enregistrée")
    expect(StudioVersion.last.site.dig("pages", "legal", "blocks", 0, "values", "title")).to eq("Nos règles et vos choix")
    visit legal_center_path
    expect(page).not_to have_css('h1', text: "Nos règles et vos choix")
  end
end
