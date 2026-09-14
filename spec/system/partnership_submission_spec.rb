require "rails_helper"
RSpec.describe "Envoi simple d’un partenariat", type: :system do
  it "remplace les décisions administratives par un envoi et un statut explicite" do
    owner = create(:profile).user
    organization = organization_space(owner: owner, kind: "company", request_kind: "partnership")
    record = organization.partnerships.create!(public_title: "Notre engagement", public_description: "Une collaboration locale.", starts_on: Date.current, ends_on: Date.current + 30)
    visit new_user_session_path
    fill_in "E-mail", with: owner.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit account_organization_path(organization, tab: "partnerships")
    expect(page).to have_content("Brouillon privé")
    expect(page).not_to have_field("Motif de décision")
    expect(page).not_to have_button("Enregistrer la décision")
    click_button "Envoyer à l’équipe SEOS"
    expect(page).to have_content("Votre proposition attend l’examen")
    expect(page).not_to have_button("Envoyer à l’équipe SEOS")
    expect(record.reload.status).to eq("pending_review")
  end
end
