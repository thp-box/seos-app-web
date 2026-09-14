require "rails_helper"
RSpec.describe "Espaces distincts de projets", type: :system do
  it "sépare les missions des partenariats et conserve les champs pendant la navigation" do
    owner = create(:profile).user
    association = organization_space(owner: owner, request_kind: "community_mission")
    partner = organization_space(owner: owner, kind: "company", request_kind: "partnership")
    visit new_user_session_path
    fill_in "E-mail", with: owner.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit account_organization_path(association)
      expect(page).to have_content(/Espace missions communautaires/i)
      expect(page).to have_button("Mes missions")
      expect(page).not_to have_button("Mes partenariats")
      expect(page).to have_css('[role="tabpanel"]', count: 1)
      page.driver.browser.action.pause(duration: 0.3).perform
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      page.save_screenshot(Rails.root.join("tmp/screenshots/organization-missions-#{width}.png"))
      click_button "Mon association"
      fill_in "Nom public", with: "Mon texte en cours"
      click_button "Vue d’ensemble"
      click_button "Mon association"
      expect(page).to have_field("Nom public", with: "Mon texte en cours")
      visit account_organization_path(partner)
      expect(page).to have_content(/Espace partenaire/i)
      expect(page).to have_button("Mes partenariats")
      expect(page).not_to have_button("Mes missions")
      click_button "Mes partenariats"
      expect(page).to have_button("Enregistrer le brouillon de partenariat")
      page.save_screenshot(Rails.root.join("tmp/screenshots/organization-partner-#{width}.png"))
    end
    visit account_organizations_path(request_kind: "partnership")
    expect(page).to have_content("Comment souhaitez-vous participer")
    page.driver.browser.action.pause(duration: 0.3).perform
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
    page.save_screenshot(Rails.root.join("tmp/screenshots/organization-request.png"))
  end
end
