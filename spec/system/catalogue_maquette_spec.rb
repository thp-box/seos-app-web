require "rails_helper"

RSpec.describe "Catalogue inspiré de la maquette", type: :system do
  it "filtre les sous-catégories, conserve les filtres avec les favoris et affiche le menu avatar" do
    parent = create(:category, name: "Savoirs et numérique")
    category = create(:category, name: "Cours et formations", parent: parent)
    listing = create(:listing, title: "Cours d’anglais pour débutant", category: category)
    listing.photos.attach(io: File.open(Rails.root.join("app/assets/images/maquette/photo-1543269865-cbf427effbad19dcd05e.jpg")), filename: "cours.jpg", content_type: "image/jpeg")
    furniture = create(:listing, title: "Aide pour monter un meuble")
    furniture.photos.attach(io: File.open(Rails.root.join("app/assets/images/maquette/photo-1586023492125-27b2c045efd7a8d3f02d.jpg")), filename: "maison.jpg", content_type: "image/jpeg")
    user = create(:profile, display_name: "Camille").user
    Notification.create!(user: user, event_key: "catalogue-test", title: "Une nouvelle réponse")
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit listings_path
    expect(page).to have_css('.nav-notification-count', text: "1")
    find('.profile-navigation > summary').click
    within('.profile-navigation') { expect(page).to have_link("Mes favoris") }
    find('.profile-navigation > summary').send_keys(:escape)
    expect(page).not_to have_css('.profile-navigation[open]')
    [ 375, 768, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true), page.evaluate_script("[...document.querySelectorAll('html,body,body *')].filter(e => e.scrollWidth > e.clientWidth + 5).map(e => [e.tagName, e.className, e.scrollWidth,e.clientWidth]).slice(0,30)").inspect
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/catalogue-maquette-#{width}.png"))
      page.execute_script("document.querySelector('.catalogue-results').scrollIntoView()")
      page.save_screenshot(Rails.root.join("tmp/screenshots/catalogue-results-#{width}.png"))
      page.execute_script("window.scrollTo(0, 0)")
    end
    fill_in "Localité", with: "Rennes"
    expect(page).to have_field("Commune", with: "Rennes")
    fill_in "Commune", with: ""
    expect(page).to have_field("Localité", with: "")
    find("#max_points").send_keys(:home, :arrow_right)
    expect(page).to have_css('[data-catalogue-target="pointsLabel"]', text: "5 PS")
    find("#max_points").send_keys(:end)
    expect(page).to have_css('[data-catalogue-target="pointsLabel"]', text: "Sans plafond")
    find('.catalogue-category-tree summary', text: parent.name).click
    check "Tout : #{parent.name}"
    click_button "Afficher les résultats"
    expect(page).to have_css('.catalogue-card', count: 1)
    expect(page).to have_content(listing.title)
    find('button.catalogue-favorite[aria-pressed="false"]').click
    expect(page).to have_current_path(listings_path, ignore_query: true)
    expect(page).to have_checked_field("Tout : #{parent.name}")
    expect(page).to have_css('button.catalogue-favorite[aria-pressed="true"]')
    find('button.catalogue-favorite[aria-pressed="true"]').click
    expect(page).to have_css('button.catalogue-favorite[aria-pressed="false"]')
    expect(user.favorites).to be_empty
    within('.catalogue-card') { click_link listing.title }
    expect(page).to have_current_path(listing_path(listing))
  end
end
