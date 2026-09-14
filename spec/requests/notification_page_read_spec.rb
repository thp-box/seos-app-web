require "rails_helper"
RSpec.describe "Lecture des notifications de la page", type: :request do
  it "ne lit que la rubrique affichée et protège les nouveaux événements et les autres comptes" do
    user = create(:profile).user
    other = create(:profile).user
    read = Notification.notify!(user: user, key: "points:old", title: "Points reçus")
    unrelated = Notification.notify!(user: user, key: "achievement:old", title: "Quête")
    foreign = Notification.notify!(user: other, key: "points:other", title: "Privé")
    login(user)
    get account_points_path
    token = Nokogiri::HTML(response.body).at_css("[data-notification-read-token-value]")["data-notification-read-token-value"]
    expect(read.reload.read_at).to be_nil
    fresh = Notification.notify!(user: user, key: "points:fresh", title: "Nouveaux points")
    patch read_page_account_notifications_path, params: { token: token }, as: :json
    expect(response).to have_http_status(:ok)
    expect(read.reload.read_at).to be_present
    [ unrelated, foreign, fresh ].each { |notice| expect(notice.reload.read_at).to be_nil }
    expect(response.parsed_body["categories"]["wallet"]).to eq(1)
    patch read_page_account_notifications_path, params: { token: "tampered" }, as: :json
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login(other)
    patch read_page_account_notifications_path, params: { token: token }, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(foreign.reload.read_at).to be_nil
  end

  it "ne lit rien simplement en ouvrant la liste des notifications" do
    user = create(:profile).user
    Notification.notify!(user: user, key: "points:one", title: "Points")
    login(user)
    get account_notifications_path
    expect(response.body).not_to include("data-notification-read-token-value")
    expect(response.body).to include("Marquer comme lue")
  end
end
