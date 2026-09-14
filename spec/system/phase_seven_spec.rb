require "rails_helper"
RSpec.describe "Accessibilité des outils de lancement", type: :system do
  it "offre les préférences, droits et outils admin sur mobile et ordinateur" do
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ privacy_preferences_path, account_privacy_path, admin_privacy_index_path, admin_operations_path, admin_studio_index_path ].each_with_index do |path, index|
      visit path
      [ 375, 1440 ].each do |width|
        resize_viewport(width)
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true), path
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
        page.save_screenshot(Rails.root.join("tmp/screenshots/phase7-#{index}-#{width}.png"))
      end
    end
  end
end

RSpec.describe "Publication et reset du Studio", type: :system do
  it "publie une variante puis restaure exactement le titre et les styles initiaux" do
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit admin_studio_index_path
    fill_in "Nom de la proposition", with: "Recette du Studio"
    find("summary", text: "Couleurs et formes du thème").click
    select "18px", from: "token-radius"
    find("summary", text: "Page : Accueil").click
    fill_in "home-title", with: "Entraidons-nous"
    click_button "Créer le brouillon"
    expect(page).to have_css("article h2", text: "Recette du Studio")
    version = StudioVersion.last
    within("article", text: "##{version.id} · Recette du Studio") do
      fill_in "Motif", with: "Prévisualisation vérifiée"
      click_button "Valider après prévisualisation"
    end
    within("article", text: "##{version.id} · Recette du Studio") do
      fill_in "Motif", with: "Recette validée"
      click_button "Publier cette version"
    end
    expect(page).to have_css("article", text: "Publié")
    expect(page).not_to have_button("Publier cette version")
    visit root_path
    expect(page).to have_css("h1", text: "Entraidons-nous")
    expect(page.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('--radius').trim()")).to eq("18px")
    visit admin_studio_index_path
    fill_in "Nom de la proposition", with: "Retour au défaut"
    select "Tout le site administrable", from: "Retour au défaut (prioritaire sur les modifications)"
    click_button "Créer le brouillon"
    expect(page).to have_css("article h2", text: "Retour au défaut")
    reset = StudioVersion.last
    %w[validate publish].each { |action| Studio.transition!(version: reset, actor: admin, action: action, reason: "Retour contrôlé") }
    visit root_path
    expect(page).to have_css("h1", text: "Un petit coup de main.")
    expect(page.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('--radius').trim()")).to eq("26px")
    expect(version.reload.page("home")["title"]).to eq("Entraidons-nous")
  end
end
