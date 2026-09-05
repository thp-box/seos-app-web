require "rails_helper"
RSpec.describe "Navigation SEOS", :"F-002", :"F-007", type: :system do
  it "charge le thème et les fontes locales sans erreur console" do
    visit root_path
    expect(page).to have_css("h1", text: "Un petit coup de main")
    page.evaluate_async_script("document.fonts.ready.then(arguments[0])")
    expect(page.evaluate_script("getComputedStyle(document.body).fontFamily")).to include("DM Sans")
    expect(page.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('--deep').trim()")).to eq("#004961")
    expect(page.evaluate_script("document.fonts.check('16px \"DM Sans\"')")).to be(true)
    errors = page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    expect(errors.map(&:message)).to be_empty
  end

  it "ouvre la navigation mobile au clavier et restaure le focus avec Échap" do
    resize_viewport(375)
    visit root_path
    summary = find(".mobile-navigation summary")
    summary.send_keys(:enter)
    within(".mobile-navigation") { expect(page).to have_link("Créer un compte") }
    summary.send_keys(:escape)
    expect(page).not_to have_css(".mobile-navigation[open]")
    expect(page.evaluate_script("document.activeElement.textContent")).to eq("Menu")
    summary.click
    find(".hero p").click
    expect(page).not_to have_css(".mobile-navigation[open]")
  end

  it "ouvre et ferme la modale avec retour au bouton déclencheur" do
    visit root_path
    click_button "Comprendre la confidentialité"
    expect(page).to have_css("dialog[open]", text: "Vos informations personnelles")
    click_button "Fermer"
    expect(page).not_to have_css("dialog[open]")
    expect(page.evaluate_script("document.activeElement.textContent")).to eq("Comprendre la confidentialité")
  end

  it "respecte reduced motion et le lien d'évitement" do
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    visit root_path
    page.driver.browser.action.send_keys(:tab).perform
    expect(page.evaluate_script("document.activeElement.textContent")).to eq("Aller au contenu")
    page.driver.browser.action.send_keys(:enter).perform
    expect(page.evaluate_script("document.activeElement.id")).to eq("main-content")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.btn')).transitionDuration")).to eq("0s")
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  it "connecte un membre avec Turbo, affiche ses sessions puis le déconnecte" do
    user = create(:user)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    within(".workspace") { click_link "Mes sessions" }
    expect(page).to have_content("Session actuelle")
    find("summary", text: "Mon espace").click
    click_button "Déconnexion"
    expect(page).to have_link("Rejoindre SEOS")
    expect(user.login_sessions.active).to be_empty
  end

  it "permet une inscription et affiche les erreurs liées aux champs" do
    visit new_user_registration_path
    fill_in "E-mail", with: "nouveau@example.test"
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42", exact: true
    fill_in "Confirmer le mot de passe", with: "UnAutreMotDePasse!42"
    click_button "Créer mon compte"
    expect(page).to have_css('[aria-invalid="true"][aria-describedby]')
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42", exact: true
    fill_in "Confirmer le mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Créer mon compte"
    expect(page).to have_css('[role="status"]', text: /confirmation|instructions/i)
  end

  it "gère une promotion depuis l'interface super-admin" do
    actor = create(:user, :super_admin)
    target = create(:user)
    visit new_user_session_path
    fill_in "E-mail", with: actor.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit super_admin_administrators_path
    fill_in "Identifiant du membre", with: target.id
    click_button "Rechercher"
    select "Administrateur", from: "Rôle"
    fill_in "Motif (sans donnée personnelle)", with: "Renfort équipe"
    click_button "Confirmer le rôle"
    expect(page).to have_content("Rôle enregistré")
    expect(target.reload).to be_admin
    expect(AuditLog.last.action).to eq("user.role_changed")
  end
end
