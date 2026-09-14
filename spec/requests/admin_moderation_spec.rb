require "rails_helper"

RSpec.describe "Modération quotidienne", type: :request do
  let(:admin) { create(:user, :admin) }
  def allow_permission(key)
    create(:admin_permission_grant, user: admin, permission: key)
  end

  it "modère une annonce publiée sans approbation préalable et bloque sa republication par l’auteur" do
    allow_permission("listings.moderate")
    listing = create(:listing, status: "draft", published_at: nil)
    ListingWorkflow.call(listing: listing, actor: listing.user, action: "publish")
    expect(listing.reload).to be_published
    login admin
    patch admin_workbench_path(listing.id, kind: "annonces"), params: { status: "paused", reason: "" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(listing.reload).to be_published
    patch admin_workbench_path(listing.id, kind: "annonces"), params: { status: "paused", reason: "Annonce abusive examinée" }
    expect(response).to have_http_status(:see_other)
    expect(listing.reload).to have_attributes(status: "paused", moderation_hold: true)
    expect { ListingWorkflow.call(listing: listing, actor: listing.user, action: "publish") }.to raise_error(Exchanges::Invalid)
    expect(AuditLog.where(target: listing, reason: "Annonce abusive examinée")).to exist
    expect(Notification.where(user: listing.user, category: "listings")).to exist
    patch admin_workbench_path(listing.id, kind: "annonces"), params: { status: "published", reason: "Situation résolue" }
    expect(listing.reload).to have_attributes(status: "published", moderation_hold: false)
  end

  it "pagine les annonces, filtre et ne montre ni brouillon ni adresse privée" do
    allow_permission("listings.moderate")
    owner = create(:profile).user
    category = create(:category)
    23.times { |i| create(:listing, user: owner, category: category, title: "Jardin #{i}", address_line: "SECRET ANN0NCE") }
    draft = create(:listing, title: "Brouillon confidentiel", status: "draft")
    login admin
    get admin_workbench_index_path(kind: "annonces")
    expect(Nokogiri::HTML(response.body).css("tbody tr").length).to eq(20)
    expect(response.body).not_to include("Brouillon confidentiel", "SECRET ANN0NCE")
    get admin_workbench_index_path(kind: "annonces", user_id: owner.id, q: "Jardin 22")
    expect(response.body).to include("1 annonces", "Jardin 22")
    get admin_workbench_path(draft.id, kind: "annonces")
    expect(response).to have_http_status(:forbidden)
  end

  it "sépare lecture, suspension et réactivation, avec protection des comptes administratifs" do
    allow_permission("users.read")
    member = create(:profile, display_name: "Camille Test", phone: "0612345678", address_line: "Adresse confidentielle").user
    login admin
    get admin_users_path(q: "Camille Test")
    expect(response.body).to include("Camille Test")
    get admin_user_path(member)
    expect(response.body).to include("Indice de confiance SEOS")
    expect(response.body).not_to include(member.email, "0612345678", "Adresse confidentielle")
    patch admin_user_path(member), params: { status: "suspended", reason: "Abus constaté" }
    expect(response).to have_http_status(:forbidden)
    session, = LoginSession.issue!(user: member, user_agent: "Chrome")
    allow_permission("users.moderate")
    patch admin_user_path(member), params: { status: "suspended", reason: "" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(member.reload).to be_active
    patch admin_user_path(member), params: { status: "suspended", reason: "Abus constaté" }
    expect(member.reload).to be_suspended
    expect(session.reload.revoked_at).to be_present
    patch admin_user_path(member), params: { status: "active", reason: "Recours accepté" }
    expect(member.reload).to be_active
    patch admin_user_path(admin), params: { status: "suspended", reason: "Tentative" }
    expect(response).to have_http_status(:forbidden)
  end

  it "ne révèle pas les avis différés et journalise la modération des avis révélés" do
    allow_permission("users.read")
    allow_permission("reports.manage")
    member = create(:profile).user
    exchange = completed_exchange(member)
    review = Review.create!(service_request: exchange, author: exchange.provider, reviewee: member, completion_answer: "yes", would_reengage: true, factual_body: "AVIS SECRET", reveal_at: 1.day.from_now)
    login admin
    get admin_user_path(member)
    expect(response.body).not_to include("AVIS SECRET")
    patch admin_user_path(member), params: { operation: "review", review_id: review.id, decision: "hide", reason: "Tentative" }
    expect(response).to have_http_status(:not_found)
    review.update!(reveal_at: 1.day.ago)
    patch admin_user_path(member), params: { operation: "review", review_id: review.id, decision: "hide", reason: "Propos inappropriés" }
    expect(response).to have_http_status(:see_other)
    expect(review.reload.removed_at).to be_present
    expect(review.invalidated_at).to be_nil
    expect(AuditLog.where(target: review, action: "review.hide")).to exist
  end

  it "réserve toute la supervision aux super administrateurs même avec une ancienne permission" do
    %w[users.read operations.read operations.manage].each { |key| allow_permission(key) }
    login admin
    get admin_root_path
    expect(response.body).not_to include("Supervision et registres")
    [ admin_operations_path, user_admin_operation_path(admin), admin_operations_path(format: "csv", resource: "user", reason: "Test") ].each do |path|
      get path
      expect(response).to have_http_status(:forbidden)
    end
    post admin_operations_path, params: { operation: "preview", ids: create(:user).id, reason: "Tentative" }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login create(:user, :super_admin)
    get admin_operations_path(resource: "user")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Explorer les registres", "Opérations sensibles")
    expect(response.body).not_to include(admin.email)
  end
  it "affiche le score publié et masque les projections retirées ainsi que les preuves privées" do
    allow_permission("users.read")
    member = create(:profile).user
    version = trust_version
    result, = TrustCalculator.new(user: member, version: version, events: [], referrals: []).call
    snapshot = TrustScoreSnapshot.create!(user: member, trust_algorithm_version: version, fingerprint: SecureRandom.hex(16), result: result.merge("score" => 82, "status" => "published"), contributions: [ { "private_note" => "PREUVE PRIVEE" } ], calculated_at: Time.current)
    TrustProfile.create!(user: member, trust_score_snapshot: snapshot)
    login admin
    get admin_user_path(member)
    expect(response.body).to include("82/100")
    expect(response.body).not_to include("PREUVE PRIVEE")
    version.update!(status: "retired")
    get admin_user_path(member)
    expect(response.body).not_to include("82/100")
  end
end
