require "rails_helper"
RSpec.describe "Authentification et sessions", :"F-003", :"US-07", :"US-08", type: :request do
  let(:user) { create(:user) }

  it "inscrit un membre sans accepter de rôle ou de statut du navigateur" do
    post user_registration_path, params: { user: { email: "  Nouveau@Example.Test  ", password: "UnMotDePasseSolide!42", password_confirmation: "UnMotDePasseSolide!42", role: "super_admin", status: "active" } }
    expect(response).to be_redirect
    created = User.find_by!(email: "nouveau@example.test")
    expect(created).to have_attributes(role: "member", status: "pending", confirmed_at: nil)
    expect(ActionMailer::Base.deliveries.last.to).to eq([ created.email ])
    get account_root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "bloque le piège anti-robot sans créer de compte" do
    expect { post user_registration_path, params: { user: { email: "robot@example.test", website: "spam" } } }.not_to change(User, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "confirme un compte et refuse de réutiliser le jeton" do
    pending_user = create(:user, :unconfirmed)
    token = pending_user.instance_variable_get(:@raw_confirmation_token)
    get user_confirmation_path, params: { confirmation_token: token }
    expect(pending_user.reload).to be_active
    get user_confirmation_path, params: { confirmation_token: token }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "refuse une confirmation expirée" do
    pending_user = create(:user, :unconfirmed)
    token = pending_user.instance_variable_get(:@raw_confirmation_token)
    travel 4.days do
      get user_confirmation_path, params: { confirmation_token: token }
      expect(pending_user.reload).to be_pending
    end
  end

  it "refuse un mot de passe incorrect" do
    login(user, password: "invalide")
    expect(response).to have_http_status(:unprocessable_content)
    expect(LoginSession.count).to eq(0)
  end

  it "refuse un compte non confirmé ou suspendu" do
    login(create(:user, :unconfirmed))
    expect(LoginSession.count).to eq(0)
    login(create(:user, status: :suspended))
    expect(LoginSession.count).to eq(0)
  end

  it "ouvre une session, affiche le compte et révoque à la déconnexion" do
    login(user)
    expect(response).to redirect_to(account_root_path)
    get account_root_path
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.headers["X-Robots-Tag"]).to include("noindex")
    get account_login_sessions_path
    expect(response.body).to include("Session actuelle")
    delete destroy_user_session_path
    expect(user.login_sessions.active.count).to eq(0)
    get account_root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "rejette la session immédiatement après révocation serveur" do
    login(user)
    user.login_sessions.last.revoke!
    get account_root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "rejette la session après suspension du compte" do
    login(user)
    user.update!(status: :suspended)
    get account_root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "rejette un cookie restauré après déconnexion" do
    login(user)
    old_cookie = cookies["_seos_session"]
    delete destroy_user_session_path
    cookies["_seos_session"] = old_cookie
    get account_root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "rafraîchit une activité ancienne sans prolonger l'expiration absolue" do
    login(user)
    recorded = user.login_sessions.last
    expiration = recorded.expires_at
    travel 6.minutes do
      get account_root_path
      expect(recorded.reload.last_seen_at).to be_within(1.second).of(Time.current)
      expect(recorded.expires_at).to eq(expiration)
    end
  end

  %i[member admin super_admin].each do |role|
    it "garde le #{role} connecté après huit heures sans activité" do
      member = create(:user, role: role)
      login(member)

      travel 8.hours do
        get account_root_path
        expect(response).to have_http_status(:ok)
        if member.administrative?
          get admin_root_path
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  it "respecte encore la durée maximale de session de douze heures" do
    login(user)
    travel 13.hours do
      get account_root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  it "permet de révoquer seulement ses propres appareils" do
    login(user)
    own = user.login_sessions.last
    foreign, = LoginSession.issue!(user: create(:user), user_agent: "Mozilla")
    delete account_login_session_path(foreign)
    expect(response).to have_http_status(:not_found)
    expect(foreign.reload.revoked_at).to be_nil
    delete account_login_session_path(own)
    expect(own.reload.revoked_at).to be_present
  end

  it "réinitialise le mot de passe une seule fois et révoque toutes les sessions" do
    login(user)
    delete destroy_user_session_path
    LoginSession.issue!(user: user, user_agent: "Firefox")
    token = user.send_reset_password_instructions
    put user_password_path, params: { user: { reset_password_token: token, password: "AutreMotDePasse!123", password_confirmation: "AutreMotDePasse!123" } }
    expect(user.reload.valid_password?("AutreMotDePasse!123")).to be(true)
    expect(user.login_sessions.active).to be_empty
    put user_password_path, params: { user: { reset_password_token: token, password: "EncoreUnMotDePasse123", password_confirmation: "EncoreUnMotDePasse123" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "refuse un jeton de récupération expiré" do
    token = user.send_reset_password_instructions
    travel 3.hours do
      put user_password_path, params: { user: { reset_password_token: token, password: "AutreMotDePasse!123", password_confirmation: "AutreMotDePasse!123" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.valid_password?("UnMotDePasseSolide!42")).to be(true)
    end
  end

  it "répond sans révéler l'existence de l'adresse lors d'une récupération" do
    [ user.email, "absent@example.test" ].each do |email|
      post user_password_path, params: { user: { email: email } }
      expect(response).to be_redirect
      follow_redirect!
      expect(response.body).to include(I18n.t("devise.passwords.send_paranoid_instructions"))
    end
  end

  it "modifie ses identifiants avec le mot de passe actuel et déconnecte" do
    login(user)
    get edit_user_registration_path
    expect(response).to have_http_status(:ok)
    put user_registration_path, params: { user: { email: user.email, current_password: "UnMotDePasseSolide!42", password: "AutreMotDePasse!123", password_confirmation: "AutreMotDePasse!123", role: "super_admin" } }
    expect(response).to redirect_to(new_user_session_path)
    expect(user.reload).to be_member
    expect(user.login_sessions.active).to be_empty
  end

  it "garde le compte intact si le mot de passe actuel est incorrect" do
    login(user)
    put user_registration_path, params: { user: { email: "intrus@example.test", current_password: "faux" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload.email).not_to eq("intrus@example.test")
  end

  it "limite les tentatives par IP" do
    21.times { post user_session_path, params: { user: { email: "absent@example.test", password: "wrong" } } }
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("300")
  end
end
