require "rails_helper"

RSpec.describe "Parcours confiance et parrainage", type: :request do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }

  it "réserve l’espace personnel au membre et ne révèle jamais le graphe ni les risques en public" do
    get account_trust_path
    expect(response).to redirect_to(new_user_session_path)
    trust_version
    sponsor = exempt_sponsor(create(:profile, display_name: "Identité privée du parrain").user)
    support(user, sponsor: sponsor)
    TrustRiskAssessment.create!(user: user, signal: "referral_cycle", evidence_count: 1, expires_at: 1.day.from_now)
    TrustRecalculationJob.perform_now(user.id)
    get profile_path(user.profile)
    expect(response.body).to include("Score provisoire", "53/100", "Données limitées")
    expect(response.body).not_to include("Identité privée du parrain", "referral_cycle", "AggregateRating")
    get trust_explanation_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Version active")
    login user
    get account_trust_path
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.body).not_to include("referral_cycle", sponsor.email)
  end

  it "affiche l’absence de note et la préparation d’une version sans inventer de données" do
    get trust_explanation_path
    expect(response.body).to include("aucune version")
    get profile_path(user.profile)
    expect(response.body).to include("données insuffisantes")
    login user
    get account_trust_path
    expect(response.body).to include("Aucun calcul disponible")
  end

  it "affiche le lien permanent, prend une objection et empêche une action étrangère" do
    sponsor = exempt_sponsor(user)
    login sponsor
    post account_trust_path, params: { operation: "issue" }
    expect(response).to have_http_status(:created)
    raw = Nokogiri::HTML(response.body).at_css("#personal_referral_link")["value"]
    get account_trust_path
    expect(response.body).to include(raw)
    newbie = create(:profile).user
    delete destroy_user_session_path
    Referrals.register_link!(newbie, ReferralLink.find_by!(owner: sponsor).id)
    login newbie
    referral = Referral.last
    post account_trust_path, params: { operation: "primary", referral_id: referral.id }
    expect(response).to have_http_status(:see_other)
    post account_trust_path, params: { operation: "object", referral_id: referral.id, reason: "Intrusion" }
    expect(response).to have_http_status(:not_found)
    delete destroy_user_session_path
    login sponsor
    get account_trust_path
    expect(response.body).to include("Signaler un usage non autorisé")
    post account_trust_path, params: { operation: "object", referral_id: referral.id, reason: "Code utilisé sans mon accord" }
    expect(response).to have_http_status(:see_other)
    expect(referral.reload.status).to eq("objected")
    post account_trust_path, params: { operation: "arbitrary" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "ouvre un recours sur son propre snapshot et permet une réponse humaine motivée" do
    trust_version
    completed_exchange(user)
    TrustRecalculationJob.perform_now(user.id)
    snapshot = TrustScoreSnapshot.last
    login user
    post account_trust_path, params: { operation: "appeal", snapshot_id: snapshot.id, statement: "Le calcul contient une erreur." }
    expect(response).to have_http_status(:see_other)
    appeal = TrustAppeal.last
    post account_trust_path, params: { operation: "appeal", snapshot_id: snapshot.id, statement: "Doublon" }
    expect(response).to have_http_status(:unprocessable_content)
    delete destroy_user_session_path
    login create(:user)
    post account_trust_path, params: { operation: "appeal", snapshot_id: snapshot.id, statement: "Accès interdit" }
    expect(response).to have_http_status(:not_found)
    delete destroy_user_session_path
    login admin
    get admin_trust_index_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(appeal.statement)
    post admin_trust_index_path, params: { operation: "appeal", record_id: appeal.id, decision: "rejected", reason: "Les deux confirmations sont présentes." }
    expect(response).to have_http_status(:see_other)
    expect(appeal.reload.status).to eq("rejected")
    delete destroy_user_session_path
    login user
    get account_trust_path
    expect(response.body).to include("Les deux confirmations sont présentes.")
  end

  it "sépare lecture, gestion, cellule risque et pouvoir du super-admin" do
    manager = create(:user, :admin)
    login manager
    get admin_trust_index_path
    expect(response).to have_http_status(:forbidden)
    grant(manager, "trust.read")
    get admin_trust_index_path
    expect(response).to have_http_status(:ok)
    post admin_trust_index_path, params: { operation: "version" }
    expect(response).to have_http_status(:forbidden)
    get risks_admin_trust_index_path
    expect(response).to have_http_status(:forbidden)
    grant(manager, "trust.manage")
    %w[version exemption].each do |operation|
      post admin_trust_index_path, params: { operation: operation }
      expect(response).to have_http_status(:forbidden)
    end
    post admin_trust_index_path, params: { operation: "risk", record_id: 1, decision: "dismissed" }
    expect(response).to have_http_status(:forbidden)
    grant(manager, "trust.risk")
    get risks_admin_trust_index_path
    expect(response).to have_http_status(:ok)
    expect(AuditLog.last.action).to eq("trust.risk.read")
    delete destroy_user_session_path
    observer = create(:user, :admin)
    grant(observer, "trust.risk")
    login observer
    get admin_trust_index_path
    expect(response).to have_http_status(:forbidden)
    get risks_admin_trust_index_path
    expect(response).to have_http_status(:ok)
  end

  it "gère les versions, exemptions, corrections et invalidations dans des transactions auditées" do
    login admin
    post admin_trust_index_path, params: { operation: "version", version: "v1-test", explanation: "Formule documentée", reason: "Préparation" }
    expect(response).to have_http_status(:see_other)
    version = TrustAlgorithmVersion.last
    post admin_trust_index_path, params: { operation: "algorithm", record_id: version.id, decision: "simulate", reason: "Scénarios vérifiés" }
    expect(response).to have_http_status(:see_other)
    expect(version.reload.status).to eq("simulated")
    post admin_trust_index_path, params: { operation: "exemption", record_id: user.id, reason: "Compte fondateur de test" }
    expect(response).to have_http_status(:see_other)
    expect(Referrals.eligible?(user)).to be(true)
    support(user)
    referral = Referral.last
    post admin_trust_index_path, params: { operation: "referral", record_id: referral.id, reason: "Soutien erroné" }
    expect(referral.reload.status).to eq("invalidated")
    completed_exchange(user)
    TrustSources.sync!(user)
    event = TrustEvent.last
    post admin_trust_index_path, params: { operation: "correct", record_id: event.id, decision: "overwrite", reason: "Test" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_trust_index_path, params: { operation: "correct", record_id: event.id, decision: "exclude", reason: "Échange erroné" }
    expect(response).to have_http_status(:see_other)
    expect(TrustEventCorrection.last.excluded).to be(true)
    post admin_trust_index_path, params: { operation: "correct", record_id: event.id, decision: "restore", reason: "Décision annulée" }
    expect(TrustEventCorrection.last.excluded).to be(false)
    post admin_trust_index_path, params: { operation: "unknown" }
    expect(response).to have_http_status(:unprocessable_content)
    get admin_trust_index_path
    expect(response).to have_http_status(:ok)
  end

  it "classe un faux positif avec motif, sans sanction et sans réouvrir une décision" do
    risk = TrustRiskAssessment.create!(user: user, signal: "repeated_pair", evidence_count: 5, expires_at: 30.days.from_now)
    login admin
    get risks_admin_trust_index_path
    expect(response.body).to include("Paire répétée")
    post admin_trust_index_path, params: { operation: "risk", record_id: risk.id, decision: "ban", reason: "Interdit" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_trust_index_path, params: { operation: "risk", record_id: risk.id, decision: "dismissed", reason: "Entraide régulière entre voisins" }
    expect(response).to have_http_status(:see_other)
    expect(risk.reload.status).to eq("dismissed")
    expect(user.reload).to be_active
    post admin_trust_index_path, params: { operation: "risk", record_id: risk.id, decision: "reviewed", reason: "Autre" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "permet de contester puis restaurer un soutien même sans version de score active" do
    referral = support(user)
    referral.with_lock { Referrals.invalidate!(referral, admin, "Retrait à vérifier") }
    login user
    get account_trust_path
    expect(response.body).to include("Contester le retrait du soutien")
    post account_trust_path, params: { operation: "appeal", referral_id: referral.id, statement: "Le code était autorisé." }
    expect(response).to have_http_status(:see_other)
    appeal = TrustAppeal.last
    delete destroy_user_session_path
    login admin
    post admin_trust_index_path, params: { operation: "appeal", record_id: appeal.id, decision: "accepted", reason: "Vérifié" }
    expect(response).to have_http_status(:unprocessable_content)
    expect { TrustGovernance.restore_referral!(referral, actor: user, reason: "Interdit") }.to raise_error(Pundit::NotAuthorizedError)
    post admin_trust_index_path, params: { operation: "restore_referral", record_id: referral.id, reason: "Autorisation confirmée par le parrain" }
    expect(response).to have_http_status(:see_other)
    expect(referral.reload.status).to eq("provisional")
    post admin_trust_index_path, params: { operation: "appeal", record_id: appeal.id, decision: "accepted", reason: "Le soutien est rétabli." }
    expect(response).to have_http_status(:see_other)
    expect(appeal.reload.status).to eq("accepted")
    post admin_trust_index_path, params: { operation: "restore_referral", record_id: referral.id, reason: "Doublon" }
    expect(response).to have_http_status(:unprocessable_content)
    referral.with_lock { Referrals.invalidate!(referral, admin, "Retrait réexaminé") }
    travel 4.days
    TrustGovernance.restore_referral!(referral, actor: admin, reason: "Rétabli après échéance")
    expect(referral.reload.status).to eq("confirmed")
  end

  it "ne contourne pas la permission risque par le journal général" do
    auditor = create(:user, :admin)
    grant(auditor, "audit.read")
    AuditLog.create!(actor: admin, target: user, action: "trust.risk.dismissed", reason: "Motif interne restreint")
    login auditor
    get admin_audit_logs_path
    expect(response.body).not_to include("Motif interne restreint")
    get admin_audit_logs_path(event: "trust.risk.dismissed")
    expect(response.body).not_to include("Motif interne restreint")
    grant(auditor, "trust.risk")
    get admin_audit_logs_path
    expect(response.body).to include("Motif interne restreint")
  end
end
