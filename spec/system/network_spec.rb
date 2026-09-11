require "rails_helper"

RSpec.describe "Interfaces des organisations et Voyage", type: :system do
  def browser_login(user)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
  end
  def check_page(name)
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/#{name}-#{width}.png"))
    end
  end

  it "consulte une mission et envoie une candidature privée sans exposer l’adresse" do
    mission = world_mission
    visit volunteer_mission_path(mission)
    expect(page).not_to have_content(mission.private_address)
    check_page("voyage-mission")
    candidate = create(:profile).user
    browser_login(candidate)
    visit volunteer_mission_path(mission)
    fill_in "Mon arrivée souhaitée", with: Date.current + 3
    fill_in "Mon départ souhaité", with: Date.current + 7
    fill_in "Ma motivation (privée, partagée uniquement avec les responsables de l’association)", with: "Je souhaite participer au jardin."
    click_button "Envoyer ma candidature"
    expect(page).to have_content("Je souhaite participer au jardin.")
    fill_in "Mon message", with: "Quels outils apporter ?"
    click_button "Envoyer le message"
    expect(page).to have_content("Quels outils apporter ?")
    check_page("voyage-candidature")
    expect(page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }).to be_empty
  end

  it "présente le profil, l’équipe et les brouillons puis la revue administrative" do
    owner = create(:profile).user
    organization = organization_space(owner: owner)
    browser_login(owner)
    visit account_organization_path(organization)
    check_page("organization-workspace")
    fill_in "E-mail du compte destinataire", with: "equipe@example.test"
    click_button "Créer une invitation privée"
    expect(page).to have_content("Invitation prête")
    expect(find_field("Lien privé de l’invitation").value).to include("invitation_token=")
  end

  it "garde la revue administrative accessible avec les formulaires de plusieurs ressources" do
    organization = organization_space
    world_mission(organization: organization)
    Partnership.create!({ organization: organization }.merge(partnership_attributes))
    browser_login(create(:user, :super_admin))
    visit admin_network_index_path
    check_page("network-admin")
    expect(page).not_to have_content(organization.legal_email)
  end
end
