require "rails_helper"
RSpec.describe "Choix du projet et de la structure", type: :system do
  it "adapte les structures à la demande sélectionnée" do
    user = create(:profile).user
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit account_organizations_path(request_kind: "partnership")
    select "Micro-entreprise", from: "Type de structure"
    select "Mission communautaire", from: "Type de demande"
    expect(page).to have_select("Type de structure", selected: "Association")
    expect(page).to have_css('#organization_kind option[value="micro_company"][disabled]', visible: :all)
    select "Partenariat", from: "Type de demande"
    select "Micro-entreprise", from: "Type de structure"
    expect(page).to have_select("Type de structure", selected: "Micro-entreprise")
  end
end
