require "rails_helper"

RSpec.describe "Interface confiance", type: :system do
  it "permet un recours sur mobile et expose seulement les preuves publiques" do
    user = create(:profile, display_name: "Camille").user
    trust_version
    support(user)
    TrustRecalculationJob.perform_now(user.id)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit account_trust_path
    expect(page).to have_content("Score provisoire : 53/100")
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/trust-account-#{width}.png"))
    end
    find("summary", text: "Calcul du").click
    fill_in "Signaler une erreur sur ce calcul", with: "Je souhaite comprendre les preuves retenues."
    click_button "Demander une revue humaine"
    expect(page).to have_content("Votre demande a été enregistrée")
    expect(page).to have_content("Je souhaite comprendre les preuves retenues.")
    visit profile_path(user.profile)
    expect(page).to have_content("53/100")
    expect(page).not_to have_content("Je souhaite comprendre les preuves retenues.")
    visit trust_explanation_path
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
    expect(page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }).to be_empty
  end
end
