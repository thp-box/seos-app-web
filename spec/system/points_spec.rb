require "rails_helper"

RSpec.describe "Interface Points Services", type: :system do
  it "valide l’accueil et montre le portefeuille sans débordement et avec des formulaires accessibles" do
    point_rules
    user = create(:profile).user
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit account_points_path
    click_button "Valider mon accueil"
    expect(page).to have_content("30 PS")
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/points-wallet-#{width}.png"))
    end
    find("summary", text: "Soumettre une preuve de quête").click
    select "Partage mensuel de SEOS", from: "Quête"
    fill_in "Preuve et contexte (privés, sans coordonnées de tiers)", with: "Publication de présentation du projet dans mon quartier."
    click_button "Demander la validation"
    expect(page).to have_content("Publication de présentation du projet dans mon quartier.")
    visit points_explanation_path
    fill_in "Valeur indicative du service en centimes (exemple : 2000 pour 20 €)", with: "2000"
    click_button "Voir le repère indicatif"
    expect(page).to have_content("10 à 10 PS")
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
    expect(page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }).to be_empty
  end
end
