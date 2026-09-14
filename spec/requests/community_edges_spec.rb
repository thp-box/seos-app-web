require "rails_helper"

RSpec.describe "Revue communautaire et droits", type: :request do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  before { point_rules; load Rails.root.join("db/community_seeds.rb") }

  it "protège les preuves jointes et soumet une quête depuis le compte" do
    quest = Achievement.create!(slug: "preuve", name: "Agir", description: "Image et compte rendu", reward_key: "share", event_name: "manual")
    login user
    image_path = Rails.root.join("tmp/community-proof.png")
    Vips::Image.black(20, 20).pngsave(image_path.to_s)
    post account_community_path, params: { operation: "quest", achievement_id: quest.id, evidence: "Compte rendu privé", proof: Rack::Test::UploadedFile.new(image_path, "image/png") }
    expect(response).to have_http_status(:see_other)
    record = UserAchievement.last
    get account_community_path
    expect(response.body).to include("Compte rendu privé", "Voir ma preuve")
    get media_path(record.proof.attachment)
    expect(response.media_type).to eq("image/jpeg")
    delete destroy_user_session_path
    get media_path(record.proof.attachment)
    expect(response).to have_http_status(:not_found)
    login admin
    get media_path(record.proof.attachment)
    expect(response).to have_http_status(:ok)
    get admin_community_index_path
    expect(response.body).to include("Voir la preuve")
  end

  it "revoit et retire un Top, traite un litige et versionne la politique" do
    listing = create(:listing, user: user)
    claim = Points::Rewards.submit!(user: user, kind: "share", evidence: "Partage")
    Points::Rewards.review!(claim, actor: admin, decision: "approved", reason: "Vérifié")
    login user
    post account_community_path, params: { operation: "top", listing_id: listing.id }
    expect(response).to have_http_status(:see_other)
    top = TopListingRequest.last
    chain = Chains.create!(actor: user, name: "Médiation")
    Chains.invite!(chain: chain, actor: user, description: "Service litigieux")
    delete destroy_user_session_path
    login admin
    post admin_community_index_path, params: { operation: "review_top", record_id: top.id, decision: "approved", reason: "Mission utile", days: 7, position: 1 }
    expect(response).to have_http_status(:see_other)
    get listings_path
    expect(response.body).to include("Top annonce")
    post account_community_path, params: { operation: "withdraw_top", record_id: top.id }
    expect(response).to have_http_status(:forbidden)
    post admin_community_index_path, params: { operation: "chain", record_id: chain.id, decision: "disputed", reason: "Médiation" }
    expect(response).to have_http_status(:see_other)
    get admin_community_index_path
    expect(response.body).to include("Service litigieux", "Mission utile")
    post admin_community_index_path, params: { operation: "policy", urgent_days: 3, top_max_days: 10, reason: "Rotation" }
    expect(response).to have_http_status(:see_other)
    expect(CommunityPolicyVersion.current.urgent_days).to eq(3)
    expect { CommunityPolicyVersion.current.update!(urgent_days: 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    delete destroy_user_session_path
    login user
    get account_community_path
    expect(response.body).to include("Mission utile")
    post account_community_path, params: { operation: "withdraw_top", record_id: top.id }
    expect(response).to have_http_status(:see_other)
    expect(listing.top_placement).to be_nil
    post account_points_path, params: { operation: "claim", kind: "chain", evidence: "Contournement" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "ne donne pas la lecture des preuves au seul gestionnaire de barèmes" do
    staff = create(:user, :admin)
    grant(staff, "community.rules")
    login staff
    get admin_community_index_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Créer une quête avec preuve")
  end
end
