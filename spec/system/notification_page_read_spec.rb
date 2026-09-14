require "rails_helper"
RSpec.describe "Lecture automatique et compteurs", type: :system do
  it "retire le badge de la page consultée sans action manuelle" do
    user = create(:profile).user
    notice = Notification.notify!(user: user, key: "points:read", title: "Points reçus")
    other = Notification.notify!(user: user, key: "achievement:stay", title: "Quête")
    visit new_user_session_path
    fill_in "E-mail", with: user.email
    fill_in "Mot de passe", with: "UnMotDePasseSolide!42"
    click_button "Se connecter"
    expect(page).to have_current_path(account_root_path)
    visit account_points_path
    expect(page).to have_css('[data-notification-category="wallet"][hidden]', visible: :all)
    expect(notice.reload.read_at).to be_present
    expect(other.reload.read_at).to be_nil
    expect(page).to have_css('.nav-notification-count', text: "1")
    visit account_notifications_path
    expect(page).to have_button("Marquer comme lue")
  end
end
