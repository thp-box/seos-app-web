require "rails_helper"
RSpec.describe "Administration des phases 1 et 2", :"F-012", :"F-016", :"F-024", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let!(:listing) { create(:listing) }
  def index_path(kind) = admin_workbench_index_path(kind: kind)
  def record_path(record, kind) = admin_workbench_path(record.id, kind: kind)

  it "refuse l’administration aux membres et les réglages du site aux admins ordinaires" do
    member = create(:user)
    login member
    Admin::WorkbenchController::RESOURCES.each_key do |kind|
      get index_path(kind)
      expect(response).to have_http_status(:forbidden)
    end
    delete destroy_user_session_path

    admin = create(:user, :admin)
    login admin
    %w[categories contenus].each do |kind|
      get index_path(kind)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "gère les sous-catégories et supprime une catégorie sans supprimer ses annonces" do
    login super_admin
    get new_admin_workbench_path(kind: "categories")
    expect(response).to have_http_status(:ok)
    post index_path("categories"), params: { record: { name: "Entraide", slug: "entraide" }, reason: "Nouveau référentiel" }
    category = Category.find_by!(slug: "entraide")
    get record_path(category, "categories")
    expect(response).to have_http_status(:ok)
    child = create(:category, parent: category)
    patch record_path(category, "categories"), params: { record: { parent_id: category.id }, reason: "Cycle interdit" }
    expect(response).to have_http_status(:unprocessable_content)
    listing.update!(category: category)
    expect { delete record_path(category, "categories"), params: { reason: "Référentiel simplifié" } }.not_to change(Listing, :count)
    expect(response).to have_http_status(:see_other)
    expect(category.reload.deleted_at).to be_present
    expect(listing.reload).to be_paused
    expect(listing.category).to eq(category)
    expect(child.reload.parent).to be_nil
    get index_path("categories")
    expect(response.body).not_to include("Entraide")
  end

  it "empêche un propriétaire de contourner un masquage de modération" do
    login super_admin
    get record_path(listing, "annonces")
    expect(response).to have_http_status(:ok)
    patch record_path(listing, "annonces"), params: { status: "paused", reason: "Revue du contenu" }
    expect(listing.reload.moderation_hold).to be(true)
    delete destroy_user_session_path
    login listing.user
    patch transition_account_listing_path(listing), params: { event: "publish", privacy_confirmed: "1" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(listing.reload).to be_paused
    delete destroy_user_session_path
    login super_admin
    patch record_path(listing, "annonces"), params: { status: "published", reason: "Contenu validé" }
    expect(listing.reload).to be_publicly_visible
  end

  it "publie des contenus versionnés sans HTML exécutable ni brouillon public" do
    login super_admin
    get new_admin_workbench_path(kind: "contenus")
    expect(response).to have_http_status(:ok)
    post index_path("contenus"), params: { record: { kind: "article", slug: "test-journal", title: "Un beau partage", body: '<script>alert(1)</script><img src="https://tracker.test/pixel">Texte', decorations: [ "wave_single" ] }, reason: "Nouvel article" }
    article = ContentVersion.last
    get article_path(article.slug)
    expect(response).to have_http_status(:not_found)
    get record_path(article, "contenus")
    expect(response).to have_http_status(:ok)
    patch record_path(article, "contenus"), params: { reason: "Validation éditoriale" }
    expect(response).to have_http_status(:see_other)
    get article_path(article.slug)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('<script>alert', '<img src="https://tracker')
    get journal_path
    expect(response.body).to include("Un beau partage")
    get new_admin_workbench_path(kind: "contenus", from: article.id)
    expect(response.body).to include("Un beau partage")
    expect { article.reload.update!(body: "Altération") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { ContentVersion.where(id: article.id).update_all(body: "Altération SQL") }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "réserve la publication au super-admin et exige des motifs de modification" do
    admin = create(:user, :admin)
    grant(admin, "content.manage")
    draft = create(:content_version)
    login admin
    patch record_path(draft, "contenus"), params: { reason: "Publication interdite" }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login super_admin
    patch record_path(listing, "annonces"), params: { status: "paused" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(listing.reload).to be_published
  end

  it "masque les conversations même au super-admin et lie leur révélation à un dossier ouvert" do
    exchange = create(:service_request, listing: listing)
    message = Message.create!(service_request: exchange, sender: exchange.requester, body: "Secret de conversation", delivery_key: "1")
    report = Report.create!(reporter: exchange.requester, reportable: message, reason: "Revue")
    login super_admin
    get record_path(exchange, "echanges")
    expect(response.body).not_to include("Secret de conversation")
    post reveal_admin_workbench_path(exchange.id, kind: "echanges"), params: { report_id: report.id, reason: "Analyse du signalement" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Secret de conversation")
    expect(AuditLog.last.action).to eq("echanges.sensitive_reveal")
    get record_path(report, "signalements")
    expect(response).to have_http_status(:ok)
    patch record_path(report, "signalements"), params: { decision: "hide", reason: "Texte retiré après revue" }
    expect(message.reload.removed_at).to be_present
    post reveal_admin_workbench_path(exchange.id, kind: "echanges"), params: { report_id: report.id, reason: "Dossier clos" }
    expect(response).to have_http_status(:not_found)
    patch record_path(report, "signalements"), params: { decision: "restore", reason: "Décision révisée" }
    expect(message.reload.removed_at).to be_nil
  end

  it "révèle les profils et contacts seulement avec audit et gère leur statut" do
    profile = listing.user.profile
    profile.update!(phone: "0612345678")
    contact = ContactRequest.create!(email: "test@example.test", message: "Question confidentielle", subject: "Aide")
    login super_admin
    get record_path(profile, "profils")
    expect(response.body).not_to include("0612345678")
    post reveal_admin_workbench_path(profile.id, kind: "profils"), params: { reason: "Demande du membre" }
    expect(response.body).to include("0612345678")
    patch record_path(profile, "profils"), params: { status: "restricted", reason: "Revue du profil" }
    expect(profile.reload).to be_restricted
    get record_path(contact, "contacts")
    expect(response.body).not_to include("Question confidentielle", "test@example.test")
    post reveal_admin_workbench_path(contact.id, kind: "contacts"), params: { reason: "Traitement de la demande" }
    expect(response.body).to include("Question confidentielle")
    patch record_path(contact, "contacts"), params: { reason: "Réponse apportée" }
    expect(contact.reload.status).to eq("resolved")
  end
end
