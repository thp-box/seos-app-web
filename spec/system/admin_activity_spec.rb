require "rails_helper"

RSpec.describe "Graphiques du tableau de bord", type: :system do
  it "affiche les courbes et permet de choisir une période et un jour sur mobile et ordinateur" do
    admin = create(:user, :admin)
    owner = create(:profile, user: create(:user, created_at: 1.year.ago)).user
    category = create(:category)
    7.times do |day|
      instant = (Date.current - 6 + day).in_time_zone + 1.minute
      (day % 4 + 1).times { create(:user, created_at: instant) }
      (day % 3).times { create(:listing, user: owner, category: category, published_at: instant) }
    end
    visit new_user_session_path
    fill_in "E-mail", with: admin.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit admin_root_path(period: 7)
      expect(page).to have_css(".activity-plot path", count: 2)
      expect(page).to have_content("7 jours précédents")
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      find("#activity-day").send_keys(:left)
      expect(find(".activity-day-summary")).to have_text(I18n.l(Date.current - 1, format: :long))
      find(".activity-chart").scroll_to(:top)
      page.save_screenshot(Rails.root.join("tmp/screenshots/dashboard-activity-#{width}.png"))
      find("summary", text: "Consulter les chiffres par jour").click
      within(".activity-chart table") { expect(page).to have_css("tbody tr", count: 7) }
      select "90 derniers jours", from: "Période"
      click_button "Actualiser"
      expect(page).to have_content("90 jours précédents")
      expect(find("#activity-day")["max"]).to eq("89")
    end
  end
end
