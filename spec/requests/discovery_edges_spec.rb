require "rails_helper"
RSpec.describe "Limites d’accès et transitions de découverte", type: :request do
  let!(:listing) { create(:listing) }
  let(:admin) { create(:user, :super_admin) }
  def record_path(record, kind) = admin_workbench_path(record.id, kind: kind)

  it "réserve la publication pour association aux memberships actifs vérifiés" do
    organization = create(:organization)
    member = create(:profile).user
    create(:organization_membership, user: member, organization: organization)
    login member
    get new_account_listing_path(organization_slug: organization.slug)
    expect(response.body).to include(organization.name)
    post account_listings_path(organization_slug: organization.slug, step: 1), params: { listing: { intent: "offer", category_id: listing.category_id } }
    expect(member.listings.last.organization).to eq(organization)
    organization.organization_memberships.last.update!(status: :revoked)
    get new_account_listing_path(organization_slug: organization.slug)
    expect(response).to have_http_status(:forbidden)
  end

  it "gère les erreurs d’annonce, la confirmation de confidentialité et les conflits d’édition" do
    login listing.user
    patch transition_account_listing_path(listing), params: { event: "publish" }
    expect(response).to have_http_status(:unprocessable_content)
    patch account_listing_path(listing, step: 2), params: { listing: { title: "x" * 121 } }
    expect(response).to have_http_status(:unprocessable_content)
    patch account_listing_path(listing, step: 2), params: { listing: { title: "Titre valide", lock_version: -1 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Ces informations ont changé")
    listing.update!(status: :closed)
    patch account_listing_path(listing), params: { listing: { title: "Réouverture interdite" } }
    expect(response).to have_http_status(:unprocessable_content)
    listing.update!(status: :paused)
    patch transition_account_listing_path(listing), params: { event: "close" }
    expect(listing.reload).to be_closed
    patch transition_account_listing_path(listing), params: { event: "remove" }
    expect(listing.reload).to be_removed
  end

  it "empêche favoris et commentaires sur une annonce non publique et garde un profil restreint" do
    login listing.user
    listing.update!(status: :draft)
    post account_favorites_path, params: { listing_slug: listing.slug }
    expect(response).to have_http_status(:not_found)
    post account_comments_path, params: { listing_slug: listing.slug, comment: { body: "Invisible" } }
    expect(response).to have_http_status(:not_found)
    listing.user.profile.update!(status: :restricted)
    patch account_profile_path, params: { profile: { display_name: "Pseudonyme modifié" } }
    expect(listing.user.profile.reload).to be_restricted
  end

  it "filtre boîtes et statuts des demandes sans mélanger les acteurs" do
    request = create(:service_request, listing: listing)
    login listing.user
    get account_service_requests_path(box: "received", status: "pending")
    expect(response.body).to include(listing.title)
    get account_service_requests_path(box: "sent")
    expect(response.body).not_to include(listing.title)
    get account_service_requests_path(status: "completed")
    expect(response.body).not_to include(listing.title)
  end

  it "réserve toute création administrative à ses ressources éditables et refuse les statuts forgés" do
    login admin
    get new_admin_workbench_path(kind: "annonces")
    expect(response).to have_http_status(:forbidden)
    post admin_workbench_index_path(kind: "annonces"), params: { record: { title: "Forcé" } }
    expect(response).to have_http_status(:forbidden)
    patch record_path(listing, "annonces"), params: { status: "forged", reason: "Test" }
    expect(response).to have_http_status(:unprocessable_content)
    patch record_path(listing.user.profile, "profils"), params: { status: "forged", reason: "Test" }
    expect(response).to have_http_status(:unprocessable_content)
    patch record_path(create(:service_request), "echanges"), params: { status: "completed", reason: "Forcé" }
    expect(response).to have_http_status(:forbidden)
    patch record_path(listing, "annonces"), params: { status: "removed", reason: "Retrait validé" }
    expect(listing.reload.removed_at).to be_present
  end

  it "exige une revue pour les catégories sensibles puis permet la validation administrative" do
    listing.update!(status: :draft)
    listing.category.update!(sensitive: true)
    login listing.user
    patch transition_account_listing_path(listing), params: { event: "publish", privacy_confirmed: "1" }
    expect(listing.reload).to be_pending_review
    expect(listing.moderation_hold?).to be(true)
    delete destroy_user_session_path
    login admin
    patch record_path(listing, "annonces"), params: { status: "published", reason: "Revue manuelle favorable" }
    expect(response).to have_http_status(:see_other)
    expect(listing.reload).to be_publicly_visible
  end

  it "interdit la réécriture d’une version publiée et respecte les publications futures" do
    article = create(:content_version, published_at: Time.current)
    login admin
    patch record_path(article, "contenus"), params: { reason: "Tentative de réécriture" }
    expect(response).to have_http_status(:unprocessable_content)
    duplicate = article.attributes.slice("kind", "slug", "title", "body")
    post admin_workbench_index_path(kind: "contenus"), params: { record: duplicate, reason: "Nouvelle version" }
    next_version = ContentVersion.order(:id).last
    expect(next_version.version).to eq(2)
    patch record_path(next_version, "contenus"), params: { reason: "Programmation", published_at: 1.day.from_now.iso8601 }
    expect(ContentVersion.current("article", article.slug)).to eq(article)
  end

  it "interdit les révélations sensibles hors permission ou dossier correspondant" do
    supporter = create(:user, :admin)
    %w[listings.moderate exchanges.support].each { |permission| grant(supporter, permission) }
    request = create(:service_request, listing: listing)
    login supporter
    post reveal_admin_workbench_path(listing.user.profile.id, kind: "profils"), params: { reason: "Sans exclusivité super-admin" }
    expect(response).to have_http_status(:forbidden)
    post reveal_admin_workbench_path(request.id, kind: "echanges"), params: { reason: "Sans droit de modération" }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login admin
    post reveal_admin_workbench_path(listing.id, kind: "annonces"), params: { reason: "Cible non sensible" }
    expect(response).to have_http_status(:forbidden)
    report = Report.create!(reporter: listing.user, reportable: listing, reason: "Autre cible")
    post reveal_admin_workbench_path(request.id, kind: "echanges"), params: { report_id: report.id, reason: "Dossier sans lien" }
    expect(response).to have_http_status(:forbidden)
  end

  it "assigne et restaure les cibles de signalements sans compléter un échange" do
    login admin
    profile = listing.user.profile
    [ listing, profile ].each do |target|
      report = Report.create!(reporter: listing.user, reportable: target, reason: "Revue")
      patch record_path(report, "signalements"), params: { decision: "assign", reason: "Prise en charge" }
      expect(report.reload.status).to eq("investigating")
      expect(report.assigned_to).to eq(admin)
      patch record_path(report, "signalements"), params: { decision: "hide", reason: "Contenu retiré" }
      patch record_path(report, "signalements"), params: { decision: "restore", reason: "Nouvelle décision" }
      expect(report.reload.status).to eq("resolved")
    end
    request = create(:service_request)
    report = Report.create!(reporter: request.requester, reportable: request, reason: "Médiation")
    patch record_path(report, "signalements"), params: { decision: "hide", reason: "Inapplicable" }
    expect(response).to have_http_status(:unprocessable_content)
    patch record_path(report, "signalements"), params: { decision: "invalidate_review", reason: "Inapplicable" }
    expect(response).to have_http_status(:unprocessable_content)
    patch record_path(report, "signalements"), params: { decision: "forged", reason: "Invalide" }
    expect(response).to have_http_status(:unprocessable_content)
    patch record_path(report, "signalements"), params: { decision: "resolve", reason: "Médiation achevée" }
    expect(request.reload).to be_pending
  end

  it "invalide un avis avec motif et protège les cibles de signalement" do
    request = create(:service_request, status: :completed, completed_at: Time.current)
    review = Review.create!(service_request: request, author: request.requester, reviewee: request.provider, completion_answer: "yes", would_reengage: true, reveal_at: 1.minute.ago)
    comment = Comment.create!(listing: listing, user: listing.user, body: "Question publique")
    message = Message.create!(service_request: request, sender: request.requester, body: "Contenu", delivery_key: "report-message")
    login request.requester
    [ review, comment, message, listing.user.profile ].each do |target|
      get new_account_report_path(target_type: target.class.name, target_id: target.id)
      expect(response).to have_http_status(:ok)
    end
    delete destroy_user_session_path
    login admin
    report = Report.create!(reporter: request.requester, reportable: review, reason: "Revue des faits")
    patch record_path(report, "signalements"), params: { decision: "invalidate_review", reason: "Éléments invalidés après revue" }
    expect(review.reload.invalidated_at).to be_present
    expect(review).not_to be_revealed
  end

  it "géocode une commune de recherche et applique le rayon avec un fournisseur de carte explicite" do
    allow(PublicGeocoding).to receive(:coordinates).with("Lyon").and_return([ 45.76, 4.84 ])
    allow(FeatureFlag).to receive(:tile_url).and_return("https://tiles.example.test/{z}/{x}/{y}.png")
    get listings_path(city: "Lyon", radius: "25", view: "map")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(listing.title)
    expect(response.headers["Content-Security-Policy"]).to include("https://tiles.example.test")
    listing.update!(intent: :request)
    get listing_path(listing)
    expect(response.body).to include('"@type":"Demand"')
  end

  it "refuse un réglage carte non motivé" do
    login admin
    get edit_super_admin_map_setting_path
    patch super_admin_map_setting_path, params: { lock_version: FeatureFlag.find_by!(key: "public_map_enabled").lock_version, enabled: "0" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(FeatureFlag.map_enabled?).to be(true)
  end
end
