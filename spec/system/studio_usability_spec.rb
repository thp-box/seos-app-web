require "rails_helper"
RSpec.describe "Lisibilité du Studio et pied de page", type: :system do
  def sign_in_admin
    admin = create(:user, :super_admin)
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    admin
  end

  def expect_footer_at_bottom
    measurements = page.evaluate_script(<<~JS)
      (() => {
        const footer = document.querySelector('body > footer').getBoundingClientRect();
        const main = document.querySelector('#main-content').getBoundingClientRect();
        return { bottom: footer.bottom + scrollY, top: footer.top, mainBottom: main.bottom,
          height: innerHeight, documentHeight: document.documentElement.scrollHeight };
      })()
    JS
    expect(measurements["bottom"]).to be >= measurements["height"] - 1
    expect((measurements["documentHeight"] - measurements["bottom"]).abs).to be <= 1
    expect(measurements["top"]).to be >= measurements["mainBottom"] - 1
  end

  it "place le pied de page en bas des pages courtes et après les contenus longs" do
    admin = sign_in_admin
    version = Studio.change!(actor: admin, name: "Page courte", settings: { "site" => { "pages" => { "courte" => { "title" => "Bienvenue", "blocks" => [ { "id" => "texte", "template" => "text", "values" => { "title" => "Bienvenue", "body" => "Notre association vous accueille." } } ] } } } })
    Studio.publish_from_review!(version: version, actor: admin, digest: version.digest, live_id: "")
    [ 375, 1440 ].each do |width|
      resize_viewport(width, height: 1400)
      [ site_page_path("courte"), root_path, account_root_path, admin_root_path ].each do |path|
        visit path
        expect_footer_at_bottom
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      end
      visit site_page_path("courte")
      if width == 1440
        expect(page.evaluate_script("Math.abs(document.querySelector('body > footer').getBoundingClientRect().bottom - innerHeight)")).to be <= 1
      end
      page.save_screenshot(Rails.root.join("tmp/screenshots/footer-bottom-#{width}.png"))
    end
  end

  it "explique les mots mis en valeur et regroupe boutons et photos sans perdre le contenu" do
    admin = sign_in_admin
    blocks = %w[home-0 home-4].map { |key| { "id" => key, "template" => key, "values" => {} } }
    version = Studio.change!(actor: admin, name: "Lisibilité", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => blocks } } } })
    visit edit_admin_site_path(version, section: "home-0")
    expect(page).to have_field("Début du titre", with: "Faites circuler")
    expect(page).to have_field("Mots du titre en couleur", with: "l’entraide.")
    expect(page).not_to have_field("⌕", visible: :all)
    expect(page).not_to have_field("⌖", visible: :all)
    find("summary", text: "Bouton 2 — ＋ Publier une annonce", exact_text: true).click
    expect(page).not_to have_field("Début du titre", visible: true)
    fill_in "Texte du bouton", with: "Proposer mon aide"
    fill_in "Page à ouvrir au clic", with: "/contact"
    find("summary", text: "Photos", exact_text: true).send_keys(:enter)
    expect(page).not_to have_field("Texte du bouton", visible: true)
    expect(page).to have_field("Photo 1 — Image à afficher")
    click_button "Enregistrer le contenu"
    expect(page).to have_content("Modifications enregistrées")
    saved = StudioVersion.last
    expect(saved.site.dig("pages", "home", "blocks", 0, "values")).to include("text-9" => "Proposer mon aide", "link-0" => "/contact")
    visit edit_admin_site_path(saved, section: "home-4")
    expect(page).to have_field("Mots du titre en couleur", with: "chaîne")
    expect(page).to have_content("Ces mots ne sont pas animés.")
    fill_in "Mots du titre en couleur", with: "vague de solidarité"
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/studio-field-labels-#{width}.png"))
    end
    click_button "Enregistrer et voir le résultat"
    within_frame(find("iframe")) { expect(page).to have_content("Votre coup de main déclenche une vague de solidarité") }
  end
end
