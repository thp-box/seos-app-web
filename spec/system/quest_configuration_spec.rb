require "rails_helper"

RSpec.describe "Configuration visuelle des quêtes", type: :system do
  it "prévisualise puis conserve l’apparence créée par l’admin" do
    point_rules
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit admin_community_index_path
    find("summary", text: "Créer une quête avec preuve").click
    within(".quest-editor") do
      fill_in "Nom de la quête", with: "Un jardin pour tous"
      fill_in "Objectif et preuve attendue", with: "Participez au jardin partagé et racontez votre coup de main."
      select "Cœur", from: "Icône"
      select "Forêt", from: "Couleur"
      select "Sans animation", from: "Animation"
      expect(page).to have_css('.quest-card[data-accent="forest"][data-animated="false"] h3', text: "Un jardin pour tous")
      expect(page).to have_css('[data-icon="heart"]', visible: true)
      expect(page).not_to have_css('[data-icon="spark"]', visible: true)
      fill_in "Pourquoi ce changement ?", with: "Animation du quartier"
    end
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/quest-editor-#{width}.png"))
    end
    click_button "Créer la quête"
    expect(page).to have_content("Décision enregistrée")
    quest = Achievement.find_by!(name: "Un jardin pour tous")
    expect(quest).to have_attributes(icon: "heart", accent: "forest", animated: false)
    visit account_community_path
    within(".quest-card") do
      expect(page).to have_content("Un jardin pour tous")
      expect(page).to have_css('progress[value="0"][max="1"]')
      find("summary", text: "Envoyer ma preuve").click
      fill_in "Votre preuve pour Un jardin pour tous", with: "J’ai planté des tomates avec les voisins."
      click_button "Soumettre à la revue"
    end
    expect(page).to have_content("Votre preuve est en cours d’examen")
    within(".quest-card") { expect(page).not_to have_selector("form") }
    reviewer = create(:user, :super_admin)
    Achievements.review!(record: UserAchievement.last, actor: reviewer, decision: "approved", reason: "Preuve vérifiée")
    visit account_community_path
    within(".quest-card") do
      expect(page).to have_content("Objectif atteint")
      expect(page).to have_css('progress[value="1"][max="1"]')
    end
  end
end
