require "rails_helper"
RSpec.describe "Présentation animée", type: :system do
  it "synchronise phrase et photo, anime les vagues et garde les visuels dans leur cadre" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Présentation", settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette") }
    resize_viewport(1440)
    visit root_path
    expect(page).to have_css('.hero-slide.active[data-label="Partage de compétences"]', wait: 9)
    expect(page).to have_css('[data-hero-carousel-target="label"]', text: "Partage de compétences")
    click_button "Mettre le diaporama en pause"
    expect(page).to have_button("Lancer le diaporama")
    click_link "▶ Comprendre en 2 minutes"
    expect(page).to have_current_path(root_path)
    expect(page.evaluate_script("location.hash")).to eq("#presentation")
    expect(page).to have_css("#presentation video")
    wave = "getComputedStyle(document.querySelector('[data-animated=true] .site-wave-layers')).transform"
    first = page.evaluate_script(wave)
    page.driver.browser.action.pause(duration: 0.4).perform
    expect(page.evaluate_script(wave)).not_to eq(first)
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      %w[home-4 home-7 home-8 home-9].each do |id|
        page.execute_script("document.querySelector('#site-section-#{id}').scrollIntoView({behavior:'instant',block:'center'})")
        page.save_screenshot(Rails.root.join("tmp/screenshots/presentation-#{id}-#{width}.png"))
      end
      expect(page.evaluate_script(<<~JS)).to be(true)
        (() => {
          const container = document.querySelector('.francophone > .container').getBoundingClientRect();
          const orb = document.querySelector('.security-orb');
          const a = orb.querySelector('[data-field="text-1"]').getBoundingClientRect();
          const b = orb.querySelector('[data-field="text-2"]').getBoundingClientRect();
          return container.left > 0 && container.right < innerWidth && b.top-a.bottom < 10;
        })()
      JS
    end
  end
end

RSpec.describe "Diaporama dans le Studio", type: :system do
  it "ajoute, modifie et supprime une diapositive puis conserve la copie" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Diaporama", settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } })
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit visual_admin_site_path(version)
    within_frame(find("iframe")) { find('.hero [data-field="text-4"]').click }
    within(".visual-inspector") do
      find("summary", text: "Diaporama et vidéo").click
      click_button "Ajouter une diapositive"
      find("summary", text: "Diaporama et vidéo").click
      find("summary", text: "Diapositive 4", exact_text: true).click
      within(find("summary", text: "Diapositive 4", exact_text: true).find(:xpath, "..")) do
        fill_in "Phrase", with: "Des liens autour du jardin"
      end
    end
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Copie enregistrée")
    expect(JSON.parse(StudioVersion.last.site.dig("pages", "home", "blocks", 0, "values", "slides")).last["label"]).to eq("Des liens autour du jardin")
    within(".visual-inspector") { click_button "Supprimer cette diapositive", match: :first }
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Copie enregistrée")
    expect(JSON.parse(StudioVersion.last.site.dig("pages", "home", "blocks", 0, "values", "slides")).size).to eq(3)
  end
end
