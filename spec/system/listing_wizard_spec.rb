require "rails_helper"
RSpec.describe "Création visuelle d’une annonce", type: :system do
  it "préremplit un exemple, sauvegarde les quatre étapes et publie les points et la photo" do
    profile = create(:profile, address_line: "12 rue Privée", public_city: "Rennes")
    create(:category, name: "Musique")
    visit new_user_session_path
    fill_in "E-mail", with: profile.user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit new_account_listing_path
    (1..4).each do |step|
      [ 375, 1440 ].each do |width|
        resize_viewport(width)
        expect(page).to have_css('[aria-current="step"]', text: step.to_s)
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
        page.save_screenshot(Rails.root.join("tmp/screenshots/listing-wizard-#{step}-#{width}.png"))
      end
      case step
      when 1
        click_button "Continuer →"
      when 2
        choose "listing_exchange_mode_points"
        fill_in "Estimation en Points Services", with: 25
        click_button "Continuer →"
      when 3
        expect(page).to have_field("Titre", with: "Cours de guitare pour débutant")
        expect(page).to have_field("Adresse exacte privée", with: "12 rue Privée")
        fill_in "Titre", with: "Découvrir la guitare ensemble"
        select "Musique", from: "Catégorie"
        select "À distance", from: "Comment se déroule le service ?"
        attach_file "Ajouter des photos", Rails.root.join("app/assets/images/maquette/photo-1543269865-cbf427effbad19dcd05e.jpg")
        click_button "Continuer →"
      when 4
        expect(page).to have_content("25 PS estimés")
        expect(page).not_to have_content("12 rue Privée")
        expect(page).to have_css('.listing-preview-photos img', count: 1)
        check "Les informations publiques et les photos ne contiennent pas mes coordonnées privées."
        click_button "Publier mon annonce"
        expect(page).to have_current_path(account_listings_path)
        expect(profile.user.listings.last).to be_published
      end
    end
  end
end
