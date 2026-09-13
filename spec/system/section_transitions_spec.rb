require "rails_helper"
RSpec.describe "Raccord des vagues aux sections", type: :system do
  it "alterne les fonds et raccorde les vagues après réorganisation et masquage" do
    admin = create(:user, :super_admin)
    document = SiteDesign.home_page
    document["blocks"] = [ document["blocks"][1], document["blocks"][4], document["blocks"][2], document["blocks"][3] ]
    document["blocks"][2]["hidden"] = true
    version = Studio.change!(actor: admin, name: "Vagues", settings: { "site" => { "pages" => { "home" => document } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette des raccords") }
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit root_path
      expect(page).not_to have_css(".yoga-separator")
      expect(page).to have_css('[data-surface-tone="deep"]')
      result = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.site-transition')).map(wave => {
          const section = wave.parentElement;
          const next = section.nextElementSibling;
          if (!next) return true;
          const path = wave.querySelector('.site-wave-main');
          const nextSurface = next.querySelector(':scope > section');
          const currentSurface = section.querySelector(':scope > section');
          return getComputedStyle(path).fill === getComputedStyle(nextSurface).backgroundColor &&
            getComputedStyle(wave.querySelector('rect')).fill === getComputedStyle(currentSurface).backgroundColor;
        })
      JS
      expect(result).to all(be(true))
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      page.execute_script("document.querySelector('#site-section-home-4').scrollIntoView()")
      page.save_screenshot(Rails.root.join("tmp/screenshots/wave-#{width}.png"))
    end
  end
end
