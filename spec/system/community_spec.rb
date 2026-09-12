require "rails_helper"

RSpec.describe "Interface engagement", type: :system do
  it "parcourt les quêtes et crée une invitation sur mobile et ordinateur" do
    point_rules
    load Rails.root.join("db/community_seeds.rb")
    user = create(:profile).user
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit account_community_path
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/community-#{width}.png"))
    end
    expect(page).to have_css('.quest-card[data-animated="true"] progress')
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.quest-card')).animationName")).to eq("none")
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
    fill_in "Votre témoignage public", with: "Un accueil chaleureux dans le quartier."
    fill_in "Nom ou pseudonyme à afficher", with: "Camille"
    check "J’autorise la publication de ce témoignage et de son nom affiché sur SEOS France. Je peux retirer cet accord à tout moment depuis cette page."
    click_button "Proposer mon témoignage"
    expect(page).to have_content("Votre demande a été enregistrée.")
    visit account_chains_path
    find("summary", text: "Commencer une chaîne").click
    fill_in "Nom de la chaîne", with: "Les voisins solidaires"
    click_button "Créer ma chaîne"
    expect(page).to have_content("Les voisins solidaires")
    fill_in "Service rendu (sans coordonnées personnelles)", with: "Aide au jardin partagé"
    click_button "Créer le lien de confirmation"
    expect(page).to have_content("Votre invitation est prête")
    expect(find_field("Lien privé de confirmation").value).to include("invitation_token=")
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
    expect(page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }).to be_empty
  end

  it "présente la revue administrative sans débordement" do
    point_rules
    load Rails.root.join("db/community_seeds.rb")
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit admin_community_index_path
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/community-admin-#{width}.png"))
    end
  end
end
