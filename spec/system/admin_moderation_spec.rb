require "rails_helper"

RSpec.describe "Espace de modération et supervision", type: :system do
  it "offre des fiches lisibles sur mobile et réserve la supervision au super administrateur" do
    admin = create(:user, :super_admin)
    member = create(:profile, display_name: "Camille Jardin").user
    listing = create(:listing, user: member)
    exchange = completed_exchange(member)
    Review.create!(service_request: exchange, author: exchange.provider, reviewee: member, completion_answer: "yes", would_reengage: true, factual_body: "Une aide très appréciée au jardin.", reveal_at: 1.day.ago)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      [ admin_users_path, admin_user_path(member), admin_workbench_index_path(kind: "annonces"), admin_workbench_path(listing.id, kind: "annonces"), admin_operations_path ].each_with_index do |path, index|
        visit path
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true), path
        page.driver.browser.action.pause(duration: 0.3).perform
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
        page.save_screenshot(Rails.root.join("tmp/screenshots/admin-moderation-#{index}-#{width}.png"))
      end
      click_button "Explorer les registres"
      expect(page).to have_select("Registre")
      expect(page).not_to have_button("Bloquer cette adresse")
      click_button "Opérations sensibles"
      expect(page).to have_button("Bloquer cette adresse")
      expect(page).not_to have_select("Registre")
      page.driver.browser.action.pause(duration: 0.3).perform
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
    end
    visit admin_user_path(member)
    find("summary", text: "Modérer cet avis").click
    select "Masquer le texte", from: "Décision"
    fill_in "Motif concernant cet avis", with: "Modération de recette"
    click_button "Appliquer la décision"
    expect(page).to have_content("Texte masqué")
  end
end
