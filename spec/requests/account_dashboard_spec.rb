require "rails_helper"

RSpec.describe "Espace personnel", type: :request do
  it "rend toutes les rubriques sans créer de portefeuille ni crédit" do
    user = create(:profile).user
    login(user)
    paths = [ account_root_path, account_listings_path, account_community_path, account_points_path, account_chains_path, account_favorites_path, account_service_requests_path, account_reviews_path, edit_account_profile_path, account_notifications_path, account_login_sessions_path, account_organizations_path, account_mission_applications_path, account_trust_path, account_privacy_path, edit_user_registration_path ]
    expect do
      paths.each do |path|
        get path
        expect(response).to have_http_status(:ok), "#{path}: #{response.status}"
        expect(response.body).to include("account-workspace"), path
      end
    end.not_to change(PointOperation, :count)
    expect(PointAccount.find_by(user: user)).to be_nil
  end

  it "ne révèle ni les avis différés ni ceux d’un autre membre" do
    user = create(:profile).user
    exchange = create(:service_request, requester: user)
    attributes = { service_request: exchange, author: exchange.provider, reviewee: user, completion_answer: "yes", would_reengage: true }
    review = Review.create!(**attributes, reveal_at: 2.days.from_now, factual_body: "Avis encore confidentiel")
    login(user)
    get account_reviews_path
    expect(response.body).not_to include("Avis encore confidentiel")
    review.update!(reveal_at: 1.minute.ago)
    get account_reviews_path
    expect(response.body).to include("Avis encore confidentiel")
    delete destroy_user_session_path
    login(create(:user))
    get account_reviews_path
    expect(response.body).not_to include("Avis encore confidentiel")
  end

  it "réserve les avis reçus aux membres connectés" do
    get account_reviews_path
    expect(response).to redirect_to(new_user_session_path)
  end
end
