require "rails_helper"
RSpec.describe "Délégations et garde-fous de la phase 7", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  it "refuse les espaces sans droit et dissocie conservation et demandes" do
    login admin
    [ admin_privacy_index_path, admin_studio_index_path, admin_operations_path ].each do |path|
      get path
      expect(response).to have_http_status(:forbidden)
    end
    grant(admin, "privacy.manage")
    get admin_privacy_index_path
    expect(response.body).to include("Demandes de droits")
    expect(response.body).not_to include("Nouvelle politique")
    post admin_privacy_index_path, params: { operation: "policy", rules: "{}" }
    expect(response).to have_http_status(:forbidden)
    admin.admin_permission_grants.update_all(revoked_at: Time.current)
    grant(admin, "privacy.rules")
    get admin_privacy_index_path
    expect(response.body).not_to include("Demandes de droits")
    task = ProviderErasureTask.create!(data_request: Privacy.request!(user: user, kind: "erasure", details: ""), provider: "google")
    post admin_privacy_index_path, params: { operation: "provider", record_id: task.id, response: "OK", reason: "Validation" }
    expect(response).to have_http_status(:forbidden)
  end
  it "audite la confirmation prestataire et les erreurs de traitement" do
    record = Privacy.request!(user: user, kind: "access", details: "")
    task = ProviderErasureTask.create!(data_request: record, provider: "backups")
    login super_admin
    post admin_privacy_index_path, params: { operation: "provider", record_id: task.id }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_privacy_index_path, params: { operation: "provider", record_id: task.id, response: "Expiration vérifiée", reason: "Contrôle" }
    expect(task.reload.status).to eq("completed")
    post admin_privacy_index_path, params: { operation: "export", record_id: record.id }
    expect(record.reload).to be_export_available
    post admin_privacy_index_path, params: { operation: "execute", record_id: record.id }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_privacy_index_path, params: { operation: "preview_purge", reason: "Test" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_privacy_index_path, params: { operation: "invalid" }
    expect(response).to have_http_status(:unprocessable_content)
    post account_privacy_path, params: { kind: "rectification", details: "Corriger mon profil" }
    expect(DataRequest.last.kind).to eq("rectification")
  end
  it "exécute une suspension après seconde validation et contrôle les blocages" do
    grant(admin, "operations.manage")
    login admin
    post admin_operations_path, params: { operation: "preview", ids: user.id, reason: "Abus" }
    operation = BulkOperation.last
    expect(operation).to be_present
    %w[block crawlers].each do |action|
      post admin_operations_path, params: { operation: action }
      expect(response).to have_http_status(:forbidden)
    end
    delete destroy_user_session_path
    login super_admin
    post admin_operations_path, params: { operation: "execute", record_id: operation.id }
    expect(user.reload).to be_suspended
    post admin_operations_path, params: { operation: "block", email: "invalid" }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_operations_path, params: { operation: "block", email: admin.email }
    expect(response).to have_http_status(:unprocessable_content)
    post admin_operations_path, params: { operation: "block", email: "abuse@example.test", expires_at: 1.day.from_now, reason: "Abus documenté" }
    expect(LoginBlock.blocked?("abuse@example.test")).to be(true)
    post admin_operations_path, params: { operation: "crawlers", search_enabled: "0", training_enabled: "1", reason: "Recette" }
    get "/robots.txt"
    expect(response.body).to include("User-agent: *\nDisallow: /", "User-agent: GPTBot\nDisallow: /compte")
    post admin_operations_path, params: { operation: "invalid" }
    expect(response).to have_http_status(:unprocessable_content)
    get admin_operations_path(resource: "user", q: user.id)
    expect(response.body).to include("1 résultats")
    get admin_operations_path(resource: "user", format: "csv")
    expect(response).to have_http_status(:unprocessable_content)
    get admin_operations_path(resource: "missing")
    expect(response).to have_http_status(:forbidden)
  end
  it "réserve la révélation au super-admin et respecte les permissions du Studio" do
    grant(admin, "users.read")
    grant(admin, "studio.preview")
    login admin
    post user_admin_operation_path(user), params: { reason: "Tentative" }
    expect(response).to have_http_status(:forbidden)
    get admin_operations_path(resource: "point_entry")
    expect(response).to have_http_status(:forbidden)
    post admin_studio_index_path, params: { operation: "upload" }
    expect(response).to have_http_status(:forbidden)
    grant(admin, "content.manage")
    post admin_studio_index_path, params: { operation: "draft", name: "Page", pages: { home: { title: "Nouveau titre", animated: "1" } } }
    expect(response).to have_http_status(:see_other)
    version = StudioVersion.last
    expect(version.page("home")["animated"]).to be(true)
    post admin_studio_index_path, params: { operation: "publish", record_id: version.id, reason: "Tentative" }
    expect(response).to have_http_status(:forbidden)
    post admin_studio_index_path, params: { operation: "draft", name: "Code", settings: "not JSON" }
    expect(response).to have_http_status(:unprocessable_content)
    get preview_admin_studio_path(version, width: 999)
    expect(response.body).to include("iframe", "1440")
    expect(response.headers["Content-Security-Policy"]).to include("frame-ancestors 'self'")
  end
end
