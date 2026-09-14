require "rails_helper"

RSpec.describe "Lien personnel de parrainage", type: :system do
  it "montre un lien stable et un suivi lisible, puis permet au super-admin de régler l’ancienneté" do
    user = create(:profile).user
    user.update!(created_at: 31.days.ago)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit account_trust_path
    click_button "Créer mon lien de parrainage"
    link = find_field("Votre lien de parrainage").value
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page).to have_field("Votre lien de parrainage", with: link)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/referral-link-#{width}.png"))
    end
    click_button "Copier mon lien"
    expect(page).to have_css('[role="status"]', text: /Lien (copié|sélectionné)/)
    visit account_trust_path
    expect(page).to have_field("Votre lien de parrainage", with: link)
    user.update!(role: :super_admin)
    visit admin_trust_index_path
    fill_in "Ancienneté minimale pour parrainer (jours)", with: 45
    click_button "Enregistrer les conditions de parrainage"
    expect(page).to have_content("Décision enregistrée et auditée")
    visit account_trust_path
    expect(page).to have_content("45 jours d’ancienneté")
    expect(page).not_to have_field("Votre lien de parrainage")
  end
end
