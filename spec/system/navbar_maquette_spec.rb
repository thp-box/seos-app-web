require "rails_helper"

RSpec.describe "Navigation publique conforme à la maquette", type: :system do
  it "place la connexion blanche avant la publication, sans troisième bouton" do
    FeatureFlag.find_or_create_by!(key: "voyage_enabled").update!(enabled: true)
    visit listings_path
    [ 1440, 1233 ].each do |width|
      resize_viewport(width)
      within(".topbar") do
        expect(page).to have_css('.nav-links [aria-current="page"]', text: "Annonces")
        expect(page).to have_link("Voyage solidaire")
        expect(page).not_to have_link("Rejoindre SEOS")
        expect(all('.nav-actions > a').map(&:text)).to eq([ "Connexion", "+ Publier une annonce" ])
        expect(find('.login-link').native.css_value("background-color")).to eq("rgba(255, 255, 255, 1)")
        expect(find('.login-link').native.rect.x).to be < find('.nav-publish').native.rect.x
      end
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/navbar-public-#{width}.png"))
    end
    resize_viewport(375)
    find('.mobile-navigation > summary').send_keys(:enter)
    within('.mobile-navigation') do
      expect(page).to have_link("Connexion", href: new_user_session_path)
      expect(page).to have_link("Créer un compte", href: new_user_registration_path)
      expect(page).to have_link("+ Publier une annonce", href: new_account_listing_path)
    end
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    resize_viewport(1440)
    within('.nav-actions') { click_link "Connexion", visible: true }
    expect(page).to have_current_path(new_user_session_path)
  end
end
