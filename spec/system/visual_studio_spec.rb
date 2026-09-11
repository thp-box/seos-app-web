require "rails_helper"
RSpec.describe "Composition visuelle", type: :system do
  it "modifie le rendu réel, déplace les sections et enregistre avant publication" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Composition", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ { "id" => "hero", "template" => "home-0", "values" => {} } ] } } } })
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit visual_admin_site_path(version)
    within_frame(find("iframe")) do
      expect(page).to have_css(".studio-drop-zone", count: 2)
      find("[data-field='text-4']").click
    end
    within(".visual-inspector") { fill_in "Mots du titre en couleur", with: "la solidarité." }
    within_frame(find("iframe")) { expect(page).to have_content("la solidarité.") }
    find(".visual-library summary", text: "Apparence et effets du site").click
    fill_in "Bleu principal", with: "#123456"
    within_frame(find("iframe")) { expect(page.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('--deep').trim()")).to eq("#123456") }
    find(".visual-library summary", text: "Ajouter une section", exact_text: true).click
    within(".visual-template[data-template='text']") { click_button "Ajouter" }
    within_frame(find("iframe")) { expect(page).to have_css("[data-studio-block]", count: 2) }
    within(".visual-inspector") { fill_in "Contenu", with: "Un espace de calme et de solidarité."; click_button "Monter" }
    within_frame(find("iframe")) { expect(page).to have_css("[data-studio-block] ~ #site-section-hero"); expect(page).to have_css("[data-studio-block]", text: "Un espace de calme") }
    click_button "Annuler"
    within_frame(find("iframe")) { expect(page).to have_css("#site-section-hero ~ [data-studio-block]") }
    click_button "Rétablir"
    within_frame(find("iframe")) { expect(page).to have_css("[data-studio-block] ~ #site-section-hero"); expect(page).to have_css("[data-studio-block]", text: "Un espace de calme") }
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Copie enregistrée. Elle n’est pas encore en ligne.")
    saved = StudioVersion.last
    expect(page).to have_link("Éditeur guidé et bibliothèque d’images", href: edit_admin_site_path(saved, page: "home", area: "pages"))
    expect(saved.status).to eq("draft")
    expect(saved.tokens["deep"]).to eq("#123456")
    expect(saved.site.dig("pages", "home", "blocks", 0, "template")).to eq("text")
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      page.save_screenshot(Rails.root.join("tmp/screenshots/visual-studio-#{width}.png"))
    end
    click_button "Vérifier et mettre en ligne"
    expect(page).to have_content("Prêt à rendre ces changements visibles ?")
    expect(page).to have_link("← Continuer les modifications", href: visual_admin_site_path(StudioVersion.last, page: "home", area: "pages"))
    click_button "Mettre en ligne"
    expect(page).to have_content("Vos modifications sont en ligne")
  end
end

RSpec.describe "Glisser-déposer dans la vraie page", type: :system do
  it "insère une section à la souris et applique ses effets sans publier" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Glisser", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ { "id" => "initial", "template" => "text", "values" => { "title" => "Notre association", "body" => "Bienvenue parmi nous." } } ] } } } })
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit visual_admin_site_path(version)
    within_frame(find("iframe")) { expect(page).to have_css(".studio-drop-zone", count: 2) }
    coordinates = page.evaluate_script(<<~JS)
      (() => {
        const source = document.querySelector('[data-template="text"]');
        source.scrollIntoView({block:'nearest'});
        const frame = document.querySelector('iframe');
        const target = frame.contentDocument.querySelector('.studio-drop-zone');
        target.scrollIntoView({block:'center'});
        const s = source.getBoundingClientRect(), f = frame.getBoundingClientRect(), t = target.getBoundingClientRect();
        const scale = f.width / frame.offsetWidth;
        return [s.x+s.width/2, s.y+10, f.x+(t.x+t.width/2)*scale, f.y+(t.y+t.height/2)*scale].map(Math.round);
      })()
    JS
    sx, sy, tx, ty = coordinates
    page.driver.browser.action.move_to_location(sx, sy).click_and_hold.pause(duration: 0.3).move_to_location(tx, ty, duration: 1).pause(duration: 0.4).release.perform
    within_frame(find("iframe")) { expect(page).to have_css("[data-studio-block]", count: 2); expect(page).to have_css("[data-studio-block] ~ #site-section-initial") }
    within(".visual-inspector") do
      find("summary", text: "Taille, espacement et effets de la section").click
      select "Respiration", from: "Animation"
      select "Aéré", from: "Espace autour du contenu"
      select "Deux vagues superposées", from: "Séparation décorative"
    end
    within_frame(find("iframe")) do
      expect(page).to have_css(".wave_double")
      expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-studio-block]')).animationName")).to eq("site-breathe")
    end
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    within_frame(find("iframe")) { expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-studio-block]')).animationName")).to eq("none") }
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Copie enregistrée. Elle n’est pas encore en ligne.")
    expect(StudioVersion.current).to be_nil
    expect(StudioVersion.last.site.dig("pages", "home", "blocks", 0, "style", "animation")).to eq("breathe")
  end
end

RSpec.describe "Pages et éléments du Studio visuel", type: :system do
  it "crée une page, règle un mot et le footer, puis retrouve ces choix après rechargement" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Pages", settings: {})
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit visual_admin_site_path(version)
    within_frame(find("iframe")) { expect(page).to have_content("Un petit coup de main") }
    find("summary", text: "Créer ou retirer une page").click
    fill_in "Nom de la nouvelle page", with: "Notre approche"
    click_button "Créer cette page"
    within(".visual-inspector") { fill_in "Contenu", with: "Prenez le temps de vous rencontrer." }
    within_frame(find("iframe")) do
      expect(page).to have_content("Prenez le temps")
      expect(page).to have_css(".studio-drop-zone")
    end
    initial_size = nil
    within_frame(find("iframe")) { initial_size = page.evaluate_script("parseFloat(getComputedStyle(document.querySelector('[data-field=title]')).fontSize)") }
    coordinates = page.evaluate_script(<<~JS)
      (() => {
        const frame = document.querySelector('iframe'), target = frame.contentDocument.querySelector('[data-field="title"]');
        target.scrollIntoView({block:'center'});
        const f = frame.getBoundingClientRect(), t = target.getBoundingClientRect(), scale = f.width / frame.offsetWidth;
        return [f.x+(t.x+20)*scale, f.y+(t.y+t.height/2)*scale].map(Math.round);
      })()
    JS
    page.driver.browser.action.move_to_location(*coordinates).click.perform
    within(".visual-inspector") do
      find("summary", text: "Taille et animation de cet élément").click
      select "Plus grand", from: "Taille de l’élément"
      select "Apparition douce", from: "Animation"
    end
    within_frame(find("iframe")) { expect(page).to have_css("style", text: "animation:site-appear", visible: :all); expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-field=title]')).animationName")).to eq("site-appear"); expect(page.evaluate_script("parseFloat(getComputedStyle(document.querySelector('[data-field=title]')).fontSize)")).to be > initial_size }
    find(".visual-library summary", text: "Haut et bas du site").click
    click_button "Modifier le bas"
    fill_in "Texte principal", with: "Une communauté qui respire."
    within_frame(find("iframe")) { expect(page).to have_content("Une communauté qui respire.") }
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Copie enregistrée. Elle n’est pas encore en ligne.")
    page.refresh
    within_frame(find("iframe")) { expect(page).to have_content("Prenez le temps"); expect(page).to have_content("Une communauté qui respire.") }
    expect(StudioVersion.last.site.dig("pages", "notre-approche", "blocks", 0, "elements", "title", "size")).to eq("large")
    expect(StudioVersion.current).to be_nil
  end
end

RSpec.describe "Édition sans confirmation périodique", type: :system do
  it "sélectionne les liens sans navigation et continue à modifier les formes après deux heures" do
    admin = create(:user, :super_admin)
    create(:category, name: "Jardinage")
    version = Studio.change!(actor: admin, name: "Reprise", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ { "id" => "categories", "template" => "home-2", "values" => {} } ] } } } })
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit visual_admin_site_path(version)
    within_frame(find("iframe")) { expect(page).to have_css(".studio-drop-zone"); expect(page).to have_content("Jardinage") }
    coordinates = page.evaluate_script(<<~JS)
      (() => {
        const frame = document.querySelector('iframe'), target = frame.contentDocument.querySelector('a[href*="category_id"]');
        target.scrollIntoView({block:'center'});
        const f = frame.getBoundingClientRect(), t = target.getBoundingClientRect(), scale = f.width/frame.offsetWidth;
        return [f.x+(t.x+20)*scale, f.y+(t.y+20)*scale].map(Math.round);
      })()
    JS
    page.driver.browser.action.move_to_location(*coordinates).click.perform
    within(".visual-inspector") do
      expect(page).to have_content("Catégories d’annonces")
      find("summary", text: "Taille, espacement et effets de la section").click
      select "Deux vagues superposées", from: "Séparation décorative"
    end
    within_frame(find("iframe")) { expect(page).to have_css(".wave_double") }
    admin.login_sessions.last.update!(reauthenticated_at: 2.hours.ago)
    within(".visual-inspector") { select "Dégradé léger", from: "Séparation décorative" }
    within_frame(find("iframe")) { expect(page).to have_css(".mist_fade"); expect(page).to have_content("Jardinage") }
    expect(page).not_to have_link("Confirmer mon mot de passe dans un autre onglet")
    click_button "Enregistrer", exact: true
    expect(page).to have_content("Copie enregistrée. Elle n’est pas encore en ligne.")
    expect(StudioVersion.last.site.dig("pages", "home", "blocks", 0, "separator")).to eq("mist_fade")
    expect(StudioVersion.current).to be_nil
  end
end
