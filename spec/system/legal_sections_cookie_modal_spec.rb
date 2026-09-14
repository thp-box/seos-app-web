require "rails_helper"
RSpec.describe "Documents continus et popup cookies", type: :system do
  it "affiche toutes les sections et ouvre les préférences sans quitter la page" do
    admin = create(:user, :super_admin)
    ContentVersion::LEGAL_SLUGS.each do |slug|
      create(:content_version, author: admin, kind: "legal", slug: slug, title: FooterHelper::LEGAL_LABELS.fetch(slug), body: "## À savoir\n\nLes informations de #{slug}.", published_at: Time.current)
    end
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit legal_center_path
      expect(page).to have_css('.legal-document', count: 5)
      expect(page).not_to have_css('[role="tabpanel"]')
      within('.legal-sidebar') { click_link "Confidentialité & RGPD" }
      expect(page).to have_current_path(%r{/legal#legal-confidentialite$}, url: true)
      expect(page).to have_css('.legal-document', count: 5)
      within('#legal-cookies') { click_link "Gérer mes cookies" }
      expect(page).to have_css('dialog[open]')
      expect(page).to have_current_path(%r{/legal#legal-confidentialite$}, url: true)
      within('dialog') do
        check "Mesure d’audience facultative"
        uncheck "Médias externes facultatifs"
        click_button "Enregistrer mes préférences"
      end
      expect(page).not_to have_css('dialog[open]')
      expect(CookieConsent.last.analytics).to be(true)
      expect(CookieConsent.last.external_media).to be(false)
      within('footer') { click_link "Gérer mes cookies" }
      expect(page).to have_css('dialog[open]')
      within('dialog') { expect(page).to have_checked_field('Mesure d’audience facultative') }
      expect(page).to be_axe_clean.within('dialog').according_to(:wcag2a, :wcag2aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/cookie-popup-#{width}.png"))
      find('dialog').send_keys(:escape)
      expect(page).not_to have_css('dialog[open]')
    end
    visit root_path
    within('footer') { click_link "Gérer mes cookies" }
    expect(page).to have_css('dialog[open]')
    expect(page).to have_current_path(root_path)
    within('dialog') { click_button "Tout refuser" }
    expect(page).not_to have_css('dialog[open]')
    expect(CookieConsent.last.analytics).to be(false)
  end
end
