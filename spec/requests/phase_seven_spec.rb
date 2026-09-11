require "rails_helper"
RSpec.describe "Parcours de confidentialité et pilotage", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  it "permet un refus puis un retrait versionnés sans traceur" do
    get privacy_preferences_path
    expect(response).to have_http_status(:ok)
    post privacy_preferences_path, params: { choice: "accept" }
    expect(CookieConsent.last.analytics).to be(true)
    post privacy_preferences_path, params: { choice: "reject" }
    expect(CookieConsent.last.analytics).to be(false)
    expect(CookieConsent.count).to eq(2)
    get privacy_preferences_path
    expect(response.headers["Cache-Control"]).to include("no-store")
    post privacy_preferences_path, params: { choice: "invalid" }
    expect(response).to have_http_status(:unprocessable_entity)
  end
  it "réserve le téléchargement au propriétaire et à une session récente" do
    login user
    get account_privacy_path
    expect(response).to have_http_status(:ok)
    post account_privacy_path, params: { kind: "access" }
    expect(response).to have_http_status(:see_other)
    record = DataRequest.last
    get download_account_privacy_path(id: record.id)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("account")["email"]).to eq(user.email)
    delete destroy_user_session_path
    login create(:user)
    get download_account_privacy_path(id: record.id)
    expect(response).to have_http_status(:not_found)
    delete destroy_user_session_path
    login user
    record.update!(export_expires_at: 1.second.ago)
    get download_account_privacy_path(id: record.id)
    expect(response).to have_http_status(:not_found)
    user.login_sessions.active.update_all(reauthenticated_at: 1.hour.ago)
    get account_privacy_path
    expect(response).to have_http_status(:ok)
    post account_privacy_path, params: { kind: "access" }
    expect(response).to redirect_to(new_account_reauthentication_path)
    get download_account_privacy_path(id: record.id)
    expect(response).to redirect_to(new_account_reauthentication_path)
    post account_reauthentication_path, params: { password: "UnMotDePasseSolide!42" }
    expect(response).to redirect_to(account_root_path)
  end
  it "masque les membres, contrôle la révélation et borne les exports" do
    login user
    get admin_operations_path
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login admin
    get admin_operations_path(resource: "user")
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(user.email)
    get user_admin_operation_path(user)
    expect(response.body).to include(user.masked_email)
    expect(response.body).not_to include(user.email)
    post user_admin_operation_path(user), params: { reason: "Support du membre" }
    expect(response.body).to include(user.email)
    get admin_operations_path(resource: "user", format: "csv", reason: "Comptage")
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(user.email)
    expect(AuditLog.where(action: "operations.export").count).to eq(1)
  end
  it "offre une prévisualisation privée et garde la publication sous contrôle" do
    login admin
    get admin_studio_index_path
    expect(response).to have_http_status(:ok)
    post admin_studio_index_path, params: { operation: "draft", name: "Essai", settings: { tokens: {}, pages: { home: { title: "Titre de démonstration" } } }.to_json }
    version = StudioVersion.last
    expect(version).to be_present
    get preview_admin_studio_path(version, width: 375, canvas: "1")
    expect(response.body).to include("Titre de démonstration")
    expect(response.headers["X-Robots-Tag"]).to include("noindex")
    get root_path
    expect(response.body).not_to include("Titre de démonstration")
    %w[validate publish].each do |operation|
      post admin_studio_index_path, params: { operation: operation, record_id: version.id, reason: "Recette" }
      expect(response).to have_http_status(:see_other)
    end
    get root_path
    expect(response.body).to include("Titre de démonstration")
  end
  it "permet le traitement et la simulation depuis l’administration" do
    record = Privacy.request!(user: user, kind: "withdrawal", details: "Retrait")
    login admin
    get admin_privacy_index_path
    expect(response).to have_http_status(:ok)
    post admin_privacy_index_path, params: { operation: "review", record_id: record.id, response: "Retrait des publications" }
    expect(record.reload.status).to eq("reviewed")
    post admin_privacy_index_path, params: { operation: "policy", name: "Revue", rules: RetentionPolicyVersion::PURPOSES.index_with { |purpose| purpose == "exports" ? 1 : 30 }.to_json, effective_at: 1.hour.from_now, expires_at: 1.year.from_now }
    expect(response).to have_http_status(:see_other)
    post admin_privacy_index_path, params: { operation: "simulate", record_id: RetentionPolicyVersion.last.id, reason: "Test" }
    expect(response).to have_http_status(:see_other)
    get admin_privacy_index_path
    expect(response.body).to include("Revue")
  end
end
