require "rails_helper"

RSpec.describe "Notifications par rubrique", type: :request do
  it "classe les événements, déduplique et n’expose que les compteurs du membre connecté" do
    user = create(:user)
    other = create(:user)
    { "message:1" => "messages", "achievement:1" => "quests", "points:1" => "wallet", "testimonial:1" => "testimonials", "referral:1" => "trust", "mission:decision:1" => "missions", "chain:1" => "chains", "review:1" => "reviews", "restriction:1" => "listings" }.each do |key, category|
      notice = Notification.notify!(user: user, key: key, title: "Une activité")
      expect(notice.category).to eq(category)
      expect { Notification.notify!(user: user, key: key, title: "Une activité") }.not_to change(Notification, :count)
    end
    Notification.notify!(user: other, key: "message:2", title: "Message privé")
    get counts_account_notifications_path
    expect(response).to redirect_to(new_user_session_path)
    login(user)
    get counts_account_notifications_path
    expect(response.parsed_body["categories"]["messages"]).to eq(1)
    expect(response.headers["Cache-Control"]).to include("no-store")
    get account_notifications_path(category: "quests")
    expect(response.body).to include("Mes quêtes")
    expect(response.body).not_to include("Message privé")
  end

  it "ouvre la bonne rubrique, refuse une notification étrangère et préserve les nouveaux événements" do
    user = create(:user)
    first = Notification.notify!(user: user, key: "points:1", title: "Votre portefeuille")
    second = Notification.notify!(user: user, key: "achievement:1", title: "Votre quête")
    fresh = Notification.notify!(user: user, key: "points:2", title: "Nouveaux points")
    foreign = Notification.notify!(user: create(:user), key: "points:3", title: "Privé")
    login(user)
    patch open_account_notification_path(foreign)
    expect(response).to have_http_status(:not_found)
    expect(foreign.reload.read_at).to be_nil
    patch read_all_account_notifications_path, params: { category: "wallet", through_id: first.id }
    expect(first.reload.read_at).to be_present
    expect(second.reload.read_at).to be_nil
    expect(fresh.reload.read_at).to be_nil
    patch open_account_notification_path(second)
    expect(response).to redirect_to(account_community_path)
    expect(second.reload.read_at).to be_present
  end

  it "efface le badge des messages lus sans toucher aux autres échanges" do
    user = create(:profile).user
    first = create(:service_request, requester: user)
    second = create(:service_request, requester: user)
    Exchanges.message!(request: first, actor: first.provider, body: "Bonjour", key: "first")
    Exchanges.message!(request: second, actor: second.provider, body: "Autre échange", key: "second")
    login(user)
    get account_service_request_path(first)
    expect(response).to have_http_status(:ok)
    expect(user.notifications.unread.where(category: "messages").count).to eq(1)
    expect(user.notifications.unread.sole.service_request_id).to eq(second.id)
  end

  it "avertit un membre lorsqu’une annonce favorite change de disponibilité" do
    listing = create(:listing)
    user = create(:user)
    Favorite.create!(user: user, listing: listing)
    listing.update!(status: "paused")
    ListingFavoritesNotificationJob.perform_now(listing.id, listing.lock_version)
    expect(user.notifications.sole.category).to eq("favorites")
    expect { ListingFavoritesNotificationJob.perform_now(listing.id, listing.lock_version) }.not_to change(Notification, :count)
  end
end
