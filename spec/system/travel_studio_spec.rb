require "rails_helper"

RSpec.describe "Présentation du voyage solidaire", type: :system do
  it "conserve le filtre et un affichage accessible sur mobile et ordinateur" do
    organization = create(:organization, name: "Entraide solidaire — Démo")
    mission = organization.volunteer_missions.create!(title: "Participer à un éco-lieu", description: "Jardinage et cuisine collective.", country_code: "FR", public_location: "Ardèche", starts_on: Date.current, ends_on: Date.current + 90, daily_contribution_points: 10, status: "published", accommodation: "Chambre partagée", meals: "Repas inclus", languages: "Français")
    File.open(Rails.root.join("app/assets/images/maquette/photo-1416879595882-3373a0480b5be3d794ff.jpg")) { |file| mission.photos.attach(io: file, filename: "garden.jpg", content_type: "image/jpeg") }
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit volunteer_missions_path
      expect(page).to have_css("h1", text: "Voyager,")
      fill_in "Filtrer par pays (code à deux lettres)", with: "FR"
      click_button "Filtrer les missions"
      expect(page).to have_current_path(volunteer_missions_path(country: "FR"))
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to have_css(".travel-card", text: "10 PS / jour")
      expect(page).not_to have_content("€/jour")
      page.execute_script("document.querySelector('.travel-card').scrollIntoView()")
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/travel-studio-#{width}.png"))
    end
  end
end
