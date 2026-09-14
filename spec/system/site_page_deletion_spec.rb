require "rails_helper"
RSpec.describe "Suppression visuelle d’une page", type: :system do
  it "retire le voyage du sélecteur et enregistre la suppression" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Suppression", settings: {})
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit visual_admin_site_path(version, page: "voyage-solidaire")
    find("summary", text: "Créer ou retirer une page").click
    accept_confirm { click_button "Retirer cette page" }
    expect(page).not_to have_css('select[data-visual-studio-target="pages"] option[value="voyage-solidaire"]', visible: :all)
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Copie enregistrée. Elle n’est pas encore en ligne.")
    expect(StudioVersion.last.deleted_pages).to include("voyage-solidaire")
  end
end
