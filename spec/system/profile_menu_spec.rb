require "rails_helper"

RSpec.describe "Menu de profil et badges", type: :system do
  it "affiche les données réelles, actualise les badges et lit les notifications par rubrique" do
    user = create(:profile, display_name: "Camille Martin").user
    fund_points(user, 73)
    user.notifications.update_all(read_at: Time.current)
    Notification.notify!(user: user, key: "achievement:1", title: "Votre première preuve a été examinée")
    Notification.notify!(user: user, key: "message:1", title: "Un message vous attend")
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit account_points_path
    find(".profile-navigation > summary").click
    [ 375, 1440 ].each do |width|
      resize_viewport(width)
      within(".profile-menu") do
        expect(page).to have_content("Camille Martin")
        expect(page).to have_content("73 Points Services")
        expect(page).to have_css('a[aria-current="page"]', text: "Mon portefeuille")
        expect(page).to have_css('[data-notification-category="quests"]', text: "1")
        expect(page).not_to have_css('[data-notification-category="favorites"]', visible: true)
        expect(page).to have_button("Se déconnecter")
      end
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21aa, :wcag22aa)
      page.save_screenshot(Rails.root.join("tmp/screenshots/profile-menu-#{width}.png"))
    end
    Notification.notify!(user: user, key: "achievement:2", title: "Une deuxième preuve a été examinée")
    page.execute_script("window.dispatchEvent(new Event('focus'))")
    within(".profile-menu") { expect(page).to have_css('[data-notification-category="quests"]', text: "2") }
    find(".profile-navigation > summary").send_keys(:escape)
    expect(page).not_to have_css(".profile-navigation[open]")
    expect(user.notifications.unread.count).to eq(3)
    visit account_notifications_path(category: "quests")
    click_button "Tout marquer comme lu dans cette sélection"
    expect(page).not_to have_button("Tout marquer comme lu dans cette sélection")
    expect(user.notifications.unread.pluck(:category)).to eq([ "messages" ])
    find(".profile-navigation > summary").click
    within(".profile-menu") do
      expect(page).not_to have_css('[data-notification-category="quests"]', visible: true)
      expect(page).to have_css('[data-notification-category="messages"]', text: "1")
      click_button "Se déconnecter"
    end
    expect(page).to have_link("Connexion")
  end
end
