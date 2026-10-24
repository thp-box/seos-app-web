require "rails_helper"

RSpec.describe "Studio V2 visuel", type: :system do
  it "décompose les compositions en éléments sélectionnables et les enregistre" do
    admin = create(:user, :super_admin)
    version = Studio.change!(
      actor: admin,
      name: "Composition V2",
      settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ { "id" => "intro", "template" => "text", "values" => { "title" => "Bienvenue chez SEOS", "body" => "Une communauté qui fait circuler l’entraide." } } ] } } } }
    )
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"

    visit builder_admin_site_path(version)
    expect(page).to have_content("Studio V2")
    expect(page).to have_content("Édition directe")
    expect(page).to have_css(".gjs-block", minimum: 8, visible: :all)
    expect(page).to have_no_css(".studio-v2-inspector")

    within_frame(find(".gjs-frame")) do
      expect(page).to have_css("header")
      expect(page).to have_css("footer")
      expect(page).to have_content("Bienvenue chez SEOS")
      find("h2", text: "Bienvenue chez SEOS").click
    end
    expect(page).to have_css('[data-studio-panel="settings"]:not([hidden])')
    expect(page).to have_content("Typographie")

    click_button "←"
    within(".studio-v2-library-switch") { click_button "Compositions" }
    expect(page).to have_css('.gjs-block[data-library-kind="section"]', minimum: 1, visible: :visible)
    within(".studio-v2-library-switch") { click_button "Éléments" }
    first(".gjs-block", text: "Titre").find(".visual-template-add").click
    within_frame(find(".gjs-frame")) do
      expect(page).to have_css("h2", text: "Votre nouveau titre")
      find("h2", text: "Votre nouveau titre").click
    end
    expect(page).to have_css(".studio-v2-selection-head", text: "ÉLÉMENT SÉLECTIONNÉ")

    click_button "Enregistrer"
    expect(page).to have_content("Modifications enregistrées")
    expect(StudioVersion.last.site.dig("pages", "home", "canvas", "html")).to include("Votre nouveau titre")
    expect(StudioVersion.last.site.dig("pages", "home", "canvas", "html")).not_to include("data-studio-chrome")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
  end
end
