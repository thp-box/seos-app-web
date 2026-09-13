require "rails_helper"
RSpec.describe "Visuels et animations initiaux", type: :system do
  it "affiche les illustrations, plusieurs courbes et respecte la réduction des animations" do
    admin = create(:user, :super_admin)
    create(:category, slug: "jardinage", name: "Jardinage")
    version = Studio.change!(actor: admin, name: "Visuels", settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette des visuels") }
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      visit root_path
      expect(page).to have_css(".home-category img")
      expect(page).to have_css(".chain-example article", count: 4)
      expect(page).to have_css(".site-wave-accent")
      expect(page.evaluate_script("new Set(Array.from(document.querySelectorAll('.site-transition')).map(e=>e.dataset.transition)).size")).to be > 1
      expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-animated=true] .site-wave-layers')).animationName")).to eq("studio-wave-drift")
      expect(page.evaluate_script("getComputedStyle(document.querySelector('.join-bubble')).animationName")).to eq("studio-orb-drift")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      page.execute_script("document.querySelector('.chain-example').scrollIntoView({block:'center'})")
      page.save_screenshot(Rails.root.join("tmp/screenshots/home-visuals-#{width}.png"))
    end
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-animated=true] .site-wave-layers')).animationName")).to eq("none")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.join-bubble')).animationName")).to eq("none")
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end
end
