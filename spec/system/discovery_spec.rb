require "rails_helper"
RSpec.describe "Parcours de découverte et d’échange", type: :system do
  def sign_in_browser(user)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
  end

  it "publie une annonce avec l’assistant puis la retrouve dans le catalogue" do
    member = create(:profile).user
    create(:category, name: "Informatique")
    sign_in_browser member
    visit new_account_listing_path
    click_button "Continuer →"
    expect(page).to have_content("Comment souhaitez-vous échanger")
    click_button "Continuer →"
    select "Informatique", from: "Catégorie"
    select "À distance", from: "Comment se déroule le service ?"
    fill_in "Titre", with: "Apprendre à utiliser un ordinateur"
    fill_in "Description publique sans coordonnées", with: "Un atelier patient pour découvrir les outils numériques."
    click_button "Continuer →"
    check "Les informations publiques et les photos ne contiennent pas mes coordonnées privées."
    click_button "Publier mon annonce"
    expect(page).to have_content("Publié")
    visit listings_path
    click_link "Apprendre à utiliser un ordinateur"
    expect(page).to have_content("À distance — France")
    expect(page).not_to have_css("[data-public-map]")
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
  end

  it "ouvre une demande et envoie un message avec Turbo" do
    listing = create(:listing)
    member = create(:profile).user
    sign_in_browser member
    visit listing_path(listing)
    click_button "Demander ce service"
    expect(page).to have_content("Conversation privée")
    fill_in "Votre message", with: "Bonjour, pourrions-nous échanger samedi ?"
    click_button "Envoyer"
    expect(page).to have_content("Bonjour, pourrions-nous échanger samedi ?")
    expect(Message.count).to eq(1)
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
  end

  it "conserve une liste accessible et ne charge aucune ressource cartographique lorsque la carte est coupée" do
    create(:listing)
    local = create(:listing, title: "Aide sur place", service_location_mode: "in_person")
    local.update!(latitude: 45.76, longitude: 4.84)
    FeatureFlag.find_or_create_by!(key: "public_map_enabled").update!(enabled: true)
    visit listings_path(view: "map")
    expect(page).to have_css(".leaflet-container")
    expect(page).to have_css(".leaflet-control-zoom-in")
    expect(page).to have_content("Aide sur place")
    expect(page).to have_content("Un coup de main au jardin")
    expect(page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }).to be_empty
    FeatureFlag.find_by!(key: "public_map_enabled").update!(enabled: false)
    visit listings_path(view: "map")
    expect(page).to have_content("Un coup de main au jardin")
    expect(page).not_to have_css("[data-public-map]")
    resources = page.evaluate_script("performance.getEntriesByType('resource').map(entry => entry.name)")
    expect(resources.grep(/leaflet|tile\\.|map-[a-f0-9]+\\.(css|js)/)).to be_empty
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
  end

  it "affiche les nouveaux écrans aux sept largeurs sans débordement et à 200 %" do
    listing = create(:listing, title: "Partager les savoir-faire du quartier")
    VisualRegression::WIDTHS.each do |width|
      resize_viewport(width)
      [ listings_path, listing_path(listing), profile_path(listing.user.profile), contact_path ].each do |path|
        visit path
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      end
    end
    resize_viewport(1280)
    visit listings_path
    page.execute_script("document.documentElement.style.zoom = '2'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= document.documentElement.clientWidth")).to be(true)
  end
end
