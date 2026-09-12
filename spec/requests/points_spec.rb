require "rails_helper"

RSpec.describe "Portefeuille et administration des points", type: :request do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  before { point_rules }

  it "garde le portefeuille privé et accorde l’accueil via une action explicite unique" do
    get account_points_path
    expect(response).to redirect_to(new_user_session_path)
    login user
    get account_points_path
    expect(response.body).to include("0 PS", "Valider mon accueil")
    post account_points_path, params: { operation: "welcome", user_id: admin.id, amount: 9000 }
    expect(response).to have_http_status(:see_other)
    get account_points_path
    expect(response.body).to include("30 PS", "Quête d’accueil terminée")
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.body).not_to include("Valider mon accueil")
    expect(PointAccount.find_by(user: admin)).to be_nil
    post account_points_path, params: { operation: "welcome" }
    expect(PointAccount.for!(user).balance).to eq(30)
    get account_points_path(user_id: admin.id, page: 2)
    expect(response.body).to include("30 PS")
    post account_points_path, params: { operation: "buy" }
    expect(response).to have_http_status(:unprocessable_content)
    delete destroy_user_session_path
    login create(:user)
    get account_points_path(user_id: user.id)
    expect(response.body).not_to include("Quête d’accueil terminée")
  end

  it "expose un barème indicatif sans données privées ni endpoint d’achat" do
    get points_explanation_path(cents: 10_000)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("50 à 50 PS", "convertibles", "Bronze")
    get points_explanation_path(cents: -1)
    expect(response).to have_http_status(:unprocessable_content)
    %w[buy sell convert withdraw].each do |action|
      post "/compte/points/#{action}", params: { amount: 20 }
      expect(response).to have_http_status(:not_found)
    end
  end

  it "confirme le montant en navigateur HTTP et affiche le solde prévisionnel puis l’écriture" do
    request = points_exchange(payer: user)
    login user
    get account_service_request_path(request)
    expect(response.body).to include("solde est insuffisant", "transfert de 20 PS")
    post account_points_path, params: { operation: "welcome" }
    patch account_service_request_path(request), params: { event: "confirm", agreement_version: request.agreement_version }
    expect(response).to have_http_status(:see_other)
    delete destroy_user_session_path
    login request.provider
    patch account_service_request_path(request), params: { event: "confirm", agreement_version: request.agreement_version }
    expect(response).to have_http_status(:see_other)
    get account_service_request_path(request)
    expect(response.body).to include("Transfert enregistré")
    get account_points_path
    expect(response.body).to include("20 PS", "Transfert de 20 PS", "Voir mon échange")
  end

  it "vérifie la preuve sans accepter un montant fourni par le membre et protège sa confidentialité" do
    login user
    post account_points_path, params: { operation: "claim", kind: "written", evidence: "Texte confidentiel du témoignage", amount: 5000, status: "approved" }
    expect(response).to have_http_status(:see_other)
    claim = PointRewardClaim.last
    expect(claim.amount).to eq(10)
    expect(claim.status).to eq("pending")
    delete destroy_user_session_path
    login admin
    get admin_points_path
    expect(response.body).to include("Texte confidentiel du témoignage")
    post admin_points_path, params: { operation: "review", record_id: claim.id, decision: "approved", reason: "Publication et contexte vérifiés" }
    expect(response).to have_http_status(:see_other)
    delete destroy_user_session_path
    login user
    get account_points_path
    expect(response.body).to include("10 PS", "Publication et contexte vérifiés")
    get profile_path(user.profile)
    expect(response.body).not_to include("Texte confidentiel du témoignage", "Publication et contexte vérifiés")
  end

  it "sépare lecture, ajustements, récompenses et règles, y compris dans le journal d’audit" do
    manager = create(:user, :admin)
    login manager
    get admin_points_path
    expect(response).to have_http_status(:forbidden)
    grant(manager, "points.read")
    get admin_points_path
    expect(response).to have_http_status(:ok)
    post admin_points_path, params: { operation: "preview", user_id: user.id, amount: 10, reason: "Test" }
    expect(response).to have_http_status(:forbidden)
    grant(manager, "points.adjust")
    post admin_points_path, params: { operation: "preview", user_id: user.id, amount: 10, reason: "Soutien motivé" }
    expect(response).to have_http_status(:see_other)
    adjustment = PointAdjustment.last
    get admin_points_path
    expect(response.body).to include("0 → 10 PS")
    post admin_points_path, params: { operation: "commit", record_id: adjustment.id, amount: 9999 }
    expect(PointAccount.for!(user).balance).to eq(10)
    post admin_points_path, params: { operation: "reverse", record_id: adjustment.reload.point_operation_id, reason: "Interdit" }
    expect(response).to have_http_status(:forbidden)
    grant(manager, "points.rules")
    post admin_points_path, params: { operation: "version", family: "engagement", name: "Interdit" }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    auditor = create(:user, :admin)
    grant(auditor, "audit.read")
    login auditor
    get admin_audit_logs_path
    expect(response.body).not_to include("Soutien motivé")
  end

  it "prépare, simule, planifie et restaure les barèmes depuis la super-administration" do
    login admin
    effective = 1.hour.from_now.change(usec: 0)
    post admin_points_path, params: { operation: "version", family: "engagement", name: "Barème V2", configuration: PointRuleVersion::DEFAULT_ENGAGEMENT.to_json, effective_at: effective.iso8601, reason: "Préparation" }
    expect(response).to have_http_status(:see_other)
    version = PointRuleVersion.last
    %w[simulate publish].each do |action|
      post admin_points_path, params: { operation: action, record_id: version.id, reason: "Contrôles validés" }
      expect(response).to have_http_status(:see_other)
    end
    get admin_points_path
    expect(response.body).to include("Barème V2", "maximum_monthly_rewards")
    post admin_points_path, params: { operation: "rollback", record_id: version.id, reason: "Retour choisi" }
    expect(response).to have_http_status(:see_other)
    post admin_points_path, params: { operation: "version", family: "valuation", name: "Invalide", configuration: "non-json", effective_at: effective.iso8601, reason: "Test" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_points_path, params: { operation: "delete" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "permet la compensation super-admin et conserve les deux opérations" do
    operation = fund_points(user, 50)
    login admin
    post admin_points_path, params: { operation: "reverse", record_id: operation.id, reason: "Erreur confirmée après médiation" }
    expect(response).to have_http_status(:see_other)
    expect(PointAccount.for!(user).balance).to eq(0)
    get admin_points_path
    expect(response.body).to include("Erreur confirmée après médiation")
    expect(PointOperation.where(id: operation.id)).to exist
  end
end
