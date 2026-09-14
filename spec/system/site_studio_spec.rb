require "rails_helper"
RSpec.describe "Studio Mon site", type: :system do
  it "compose une page, règle le kit et publie depuis une navigation explicite" do
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit admin_site_index_path
    within("article", text: "La première page que découvrent") { click_button "Modifier cette page" }
    within(".editor-template", text: "Grande présentation avec photo") { click_button "Ajouter cette partie" }
    expect(page).to have_css(".site-block", count: 1)
    click_link "Modifier le contenu"
    fill_in "Petit texte au-dessus du titre", with: "Bienvenue dans notre communauté"
    click_button "Enregistrer le contenu"
    expect(page).to have_content("Modifications enregistrées")
    version = StudioVersion.last
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/site-editor-#{width}.png"))
    end
    visit edit_admin_site_path(version, area: "kit")
    find("summary", text: "Animations et vagues").click
    select "Un mouvement toutes les 12 secondes", from: "Durée d’un cycle de vague"
    find("summary", text: "Formes et espaces").click
    select "Léger", from: "Arrondi des boutons"
    click_button "Enregistrer l’apparence"
    expect(page).to have_content("Modifications enregistrées")
    version = StudioVersion.last
    page.save_screenshot(Rails.root.join("tmp/screenshots/site-kit-editor.png"))
    click_link "Voir le résultat"
    expect(page).to have_css("h1", text: "Vérifier avant de mettre en ligne")
    click_button "Mettre en ligne"
    expect(page).to have_content("Vos modifications sont en ligne")
    visit root_path
    expect(page).to have_content(/Bienvenue dans notre communauté/i)
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page.evaluate_script("getComputedStyle(document.querySelector('.maquette-surface .btn')).borderRadius")).to eq("26px")
      expect(page.evaluate_script("document.querySelector('.hero-content p').getBoundingClientRect().bottom <= document.querySelector('.search-bar').getBoundingClientRect().top")).to be(true)
      page.save_screenshot(Rails.root.join("tmp/screenshots/site-public-#{width}.png"))
    end
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.hero-organic-cut')).animationName")).to eq("none")
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
    visit kit_admin_site_path(version)
    page.save_screenshot(Rails.root.join("tmp/screenshots/site-kit-reference.png"))
  end
end

RSpec.describe "Création de page guidée", type: :system do
  it "accompagne la cliente du nom de la page à sa mise en ligne" do
    user = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit admin_root_path
    click_link "Gérer les pages"
    expect(page).not_to have_field("Nom du chantier")
    click_link "Créer une page"
    fill_in "Nom de la page", with: "Notre association"
    click_button "Créer et écrire le contenu"
    expect(page).to have_content("Votre page est créée")
    expect(page).to have_field("Contenu")
    expect(page).not_to have_field("Destination", visible: true)
    fill_in "Contenu", with: "Nous aidons les habitants du quartier."
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/studio-admin-content-#{width}.png"))
    end
    click_button "Enregistrer et voir le résultat"
    expect(page).to have_css("h1", text: "Vérifier avant de mettre en ligne")
    expect(page).not_to have_field("Motif de validation / publication")
    within_frame(find("iframe")) { expect(page).to have_content("Nous aidons les habitants du quartier.") }
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/studio-admin-review-#{width}.png"))
    end
    click_button "Mettre en ligne"
    expect(page).to have_content("Vos modifications sont en ligne")
    visit site_page_path("notre-association")
    expect(page).to have_content("Nous aidons les habitants du quartier.")
  end
end
