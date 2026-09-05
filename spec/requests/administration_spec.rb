require "rails_helper"
RSpec.describe "Administration", :"F-004", :"F-005", type: :request do
  it "protège chaque entrée des visiteurs" do
    [ admin_root_path, admin_users_path, admin_audit_logs_path, super_admin_root_path, super_admin_administrators_path ].each do |path|
      get path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "refuse les namespaces admin à un membre" do
    login(create(:user))
    [ admin_root_path, admin_users_path, admin_audit_logs_path, super_admin_root_path, super_admin_administrators_path ].each do |path|
      get path
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Accès refusé")
    end
  end

  it "affiche le dashboard mais refuse chaque section sans permission" do
    login(create(:user, :admin))
    get admin_root_path
    expect(response.body).to include("Aucune section")
    [ admin_users_path, admin_audit_logs_path, super_admin_root_path ].each do |path|
      get path
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "filtre et pagine les membres sans divulguer d'e-mail" do
    admin = create(:user, :admin)
    grant(admin, "users.read")
    members = create_list(:user, 21)
    login(admin)
    get admin_users_path, params: { role: "member", status: "active" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("21 membres", "Page suivante", "role=member")
    expect(response.body).not_to include(members.first.email)
    get admin_users_path, params: { page: 2, role: "member", status: "active" }
    expect(response.body).to include("Page précédente", members.first.masked_email)
    get admin_users_path, params: { q: "##{members.last.id}" }
    expect(response.body).to include("1 membres")
    get admin_users_path, params: { q: "inconnu" }
    expect(response.body).to include("Aucun membre")
  end

  it "exige une réauthentification après 15 minutes" do
    admin = create(:user, :super_admin)
    login(admin)
    admin.login_sessions.last.update!(reauthenticated_at: 16.minutes.ago)
    get super_admin_root_path
    expect(response).to redirect_to(new_account_reauthentication_path)
    get new_account_reauthentication_path
    expect(response).to have_http_status(:ok)
    post account_reauthentication_path, params: { password: "incorrect" }
    expect(response).to have_http_status(:unprocessable_content)
    post account_reauthentication_path, params: { password: "UnMotDePasseSolide!42" }
    expect(response).to redirect_to(super_admin_root_path)
    get super_admin_root_path
    expect(response).to have_http_status(:ok)
  end

  it "retourne l'admin à son dashboard après vérification" do
    login(create(:user, :admin))
    post account_reauthentication_path, params: { password: "UnMotDePasseSolide!42" }
    expect(response).to redirect_to(admin_root_path)
  end

  it "refuse une promotion à l'admin ordinaire" do
    login(create(:user, :admin))
    target = create(:user)
    patch super_admin_administrator_path(target), params: { role: "admin", reason: "Support" }
    expect(response).to have_http_status(:forbidden)
    expect(target.reload).to be_member
  end

  it "permet au super-admin de promouvoir, attribuer puis révoquer un droit avec audit" do
    actor = create(:user, :super_admin)
    target = create(:user)
    login(actor)
    get super_admin_administrators_path(user_id: target.id)
    expect(response).to have_http_status(:ok)
    patch super_admin_administrator_path(target), params: { role: "admin", reason: "Renfort support" }
    expect(target.reload).to be_admin
    post super_admin_administrator_permission_grants_path(target), params: { permission: "users.read", expires_at: 1.day.from_now.iso8601, reason: "Support" }
    permission = target.admin_permission_grants.last
    expect(permission).to be_present
    get super_admin_administrators_path(user_id: target.id)
    expect(response.body).to include("users.read", "Révoquer la permission")
    delete super_admin_administrator_permission_grant_path(target, permission), params: { reason: "Fin de mission" }
    expect(permission.reload.revoked_at).to be_present
    get admin_audit_logs_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("3 événements", "Renfort support")
    get admin_audit_logs_path, params: { event: "permission.granted" }
    expect(response.body).to include("1 événements")
  end

  it "affiche les erreurs de rôle et de permission sans mutation" do
    login(create(:user, :super_admin))
    target = create(:user, :admin)
    patch super_admin_administrator_path(target), params: { role: "super_admin", reason: "Interdit" }
    follow_redirect!
    expect(response.body).to include("Rôle non autorisé")
    post super_admin_administrator_permission_grants_path(target), params: { permission: "users.read", expires_at: "erreur", reason: "Support" }
    expect(response).to redirect_to(super_admin_administrators_path)
    expect(target.admin_permission_grants).to be_empty
  end

  it "renvoie des états vides et protège les super-admins" do
    actor = create(:user, :super_admin)
    login(actor)
    get super_admin_administrators_path(user_id: -1)
    expect(response.body).to include("Membre introuvable", "Aucun administrateur")
    get super_admin_administrators_path(user_id: actor.id)
    expect(response.body).not_to include("Confirmer le rôle")
    get admin_audit_logs_path
    expect(response.body).to include("Aucun événement")
  end
end
