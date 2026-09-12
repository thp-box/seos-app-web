require "rails_helper"

RSpec.describe "Dashboard de la maquette", type: :system do
  it "présente toutes les rubriques sur téléphone et ordinateur" do
    point_rules
    user = create(:profile).user
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    paths = [ account_root_path, account_listings_path, account_favorites_path, account_chains_path, account_reviews_path, edit_account_profile_path, account_service_requests_path, account_notifications_path, account_login_sessions_path, account_organizations_path, account_mission_applications_path, account_privacy_path, account_trust_path, edit_user_registration_path ]
    paths.each do |path|
      visit path
      [ 375, 1440 ].each do |width|
        resize_viewport(width)
        expect(page).to have_css(".account-workspace")
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true), "Débordement #{path} à #{width}"
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      end
      page.save_screenshot(Rails.root.join("tmp/screenshots/dashboard-#{path.parameterize}.png"))
    end
  end
  it "affiche les annonces et les messages réels dans les cartes et la conversation" do
    user = create(:profile).user
    listing = create(:listing, user: user)
    listing.photos.attach(io: File.open(Rails.root.join("app/assets/images/maquette/photo-1586023492125-27b2c045efd7a8d3f02d.jpg")), filename: "salon.jpg", content_type: "image/jpeg")
    exchange = create(:service_request, provider: user, listing: listing)
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ account_listings_path, account_service_request_path(exchange) ].each do |path|
      visit path
      [ 375, 1440 ].each do |width|
        resize_viewport(width)
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
        page.save_screenshot(Rails.root.join("tmp/screenshots/dashboard-content-#{path.parameterize}-#{width}.png"))
      end
    end
    fill_in "Votre message", with: "Bonjour, quand seriez-vous disponible ?"
    click_button "Envoyer"
    expect(page).to have_css(".message.mine", text: "Bonjour, quand seriez-vous disponible ?")
    expect(exchange.messages.last.body).to eq("Bonjour, quand seriez-vous disponible ?")
  end
end
