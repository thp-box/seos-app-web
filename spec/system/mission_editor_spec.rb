require "rails_helper"

RSpec.describe "Création et suivi des missions", type: :system do
  it "sépare le suivi du formulaire et conserve les champs entre les étapes" do
    owner = create(:profile).user
    organization = organization_space(owner: owner, request_kind: "community_mission")
    18.times { |index| organization.volunteer_missions.create!(title: "Mission numéro #{index}") }
    visit new_user_session_path
    fill_in "E-mail", with: owner.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit account_organization_path(organization, tab: "missions")
      expect(page).to have_css(".mission-tracking-table tbody tr", count: 15)
      expect(page).not_to have_field("Titre de la mission")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      page.driver.browser.action.pause(duration: 0.3).perform
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/mission-tracking-#{width}.png"))
    end
    click_link "+ Créer une mission"
    fill_in "Titre de la mission", with: "Un jardin ensemble"
    click_button "Continuer →"
    fill_in "Localisation publique", with: "Lyon"
    click_button "← Précédent"
    expect(page).to have_field("Titre de la mission", with: "Un jardin ensemble")
    click_button "Continuer →"
    expect(page).to have_field("Localisation publique", with: "Lyon")
    click_button "Continuer →"
    fill_in "Bénévoles accueillis simultanément", with: ""
    click_button "1 Le projet"
    click_button "Enregistrer le brouillon de mission"
    expect(page).to have_field("Bénévoles accueillis simultanément")
    fill_in "Bénévoles accueillis simultanément", with: "3"
    page.driver.browser.action.pause(duration: 0.3).perform
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.save_screenshot(Rails.root.join("tmp/screenshots/mission-editor-mobile.png"))
    click_button "Enregistrer le brouillon de mission"
    expect(page).to have_link("Un jardin ensemble")
    expect(organization.volunteer_missions.find_by!(title: "Un jardin ensemble")).to have_attributes(status: "draft", public_location: "Lyon", volunteer_capacity: 3)
  end
end
