require "rails_helper"
RSpec.describe "Échanges privés et avis", :"F-020", :"F-021", :"F-022", :"F-023", :"F-024", type: :request do
  let!(:listing) { create(:listing) }
  let(:requester) { create(:profile).user }
  let(:provider) { listing.user }
  let(:exchange) { Exchanges.create!(listing: listing, actor: requester) }
  it "protège les conversations, les notifications et leurs pièces jointes contre les tiers" do
    exchange
    login requester
    get account_service_requests_path
    expect(response).to have_http_status(:ok)
    post account_service_request_messages_path(exchange), params: { message: { body: "Conversation confidentielle", delivery_key: "browser-1" } }
    expect(response).to have_http_status(:see_other)
    get account_service_request_path(exchange)
    expect(response.body).to include("Conversation confidentielle")
    delete destroy_user_session_path
    login provider
    get account_service_request_path(exchange)
    expect(Message.last.read_at).to be_present
    get account_notifications_path
    expect(response).to have_http_status(:ok)
    patch account_notification_path(provider.notifications.last)
    patch preferences_account_notifications_path, params: { user: { email_notifications: "0", role: "member" } }
    expect(provider.reload.email_notifications).to be(false)
    delete destroy_user_session_path
    login create(:user, :super_admin)
    get account_service_request_path(exchange)
    expect(response).to have_http_status(:not_found)
    post account_service_request_messages_path(exchange), params: { message: { body: "Intrusion", delivery_key: "2" } }
    expect(response).to have_http_status(:not_found)
  end

  it "connecte le parcours demande, accord et double confirmation aux avis structurés" do
    create(:review_criterion)
    login requester
    post account_service_requests_path, params: { listing_slug: listing.slug }
    record = ServiceRequest.last
    delete destroy_user_session_path
    login provider
    patch account_service_request_path(record), params: { event: "accept" }
    patch account_service_request_path(record), params: { event: "propose", terms: { scheduled_at: 1.day.from_now.iso8601, location: "Appel privé", mode: "remote" } }
    expect(response).to have_http_status(:see_other)
    get account_service_request_path(record)
    expect(response.body).to include("Appel privé", "version 1")
    delete destroy_user_session_path
    login requester
    patch account_service_request_path(record), params: { event: "agree", agreement_version: 1 }
    patch account_service_request_path(record), params: { event: "confirm" }
    delete destroy_user_session_path
    login provider
    patch account_service_request_path(record), params: { event: "confirm" }
    expect(record.reload).to be_completed
    ratings = ReviewCriterion.applicable(record, provider).pluck(:id).to_h { |id| [ id.to_s, "5" ] }
    post account_service_request_reviews_path(record), params: { review: { completion_answer: "yes", would_reengage: "true", factual_body: "Premier avis aveugle" }, ratings: ratings }
    expect(response).to have_http_status(:see_other)
    first = Review.last
    get profile_path(requester.profile)
    expect(response.body).not_to include("Premier avis aveugle")
    delete destroy_user_session_path
    login requester
    get account_service_request_path(record)
    expect(response.body).not_to include("Premier avis aveugle")
    post account_service_request_reviews_path(record), params: { review: { completion_answer: "yes", would_reengage: "true", factual_body: "Deuxième avis" }, ratings: ratings }
    expect(first.reload).to be_revealed
    get account_service_request_path(record)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Premier avis aveugle", "Deuxième avis")
    patch account_review_path(first), params: { review: { response: "Merci pour cet échange" } }
    expect(first.reload.response).to include("Merci")
  end

  it "signale et bloque uniquement depuis une ressource accessible" do
    login requester
    get new_account_report_path(target_type: "ServiceRequest", target_id: exchange.id)
    expect(response).to have_http_status(:ok)
    post account_reports_path, params: { target_type: "ServiceRequest", target_id: exchange.id, report: { reason: "Besoin de médiation", details: "Contexte privé" } }
    expect(Report.last.reporter).to eq(requester)
    post account_user_blocks_path, params: { service_request_id: exchange.id }
    expect(exchange.blocked?).to be(true)
    delete account_user_block_path(UserBlock.last)
    expect(exchange.blocked?).to be(false)
    get new_account_report_path(target_type: "User", target_id: provider.id)
    expect(response).to have_http_status(:not_found)
    get new_account_report_path(target_type: "Listing", target_id: listing.id)
    expect(response).to have_http_status(:ok)
    delete destroy_user_session_path
    login create(:user)
    get new_account_report_path(target_type: "ServiceRequest", target_id: exchange.id)
    expect(response).to have_http_status(:not_found)
  end
end
