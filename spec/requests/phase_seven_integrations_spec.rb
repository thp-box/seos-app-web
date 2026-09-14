require "rails_helper"
RSpec.describe "Intégrations et pièces de la phase 7", type: :request do
  let(:admin) { create(:user, :super_admin) }
  it "lie Google, renouvelle la session et respecte la réauthentification" do
    user = create(:user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "verified-sub", info: { email_verified: true, email: user.email })
    login user
    get user_google_oauth2_omniauth_callback_path
    expect(response).to redirect_to(account_root_path)
    expect(GoogleIdentity.last.user).to eq(user)
    user.login_sessions.active.update_all(reauthenticated_at: 1.hour.ago)
    get user_google_oauth2_omniauth_callback_path
    expect(response).to redirect_to(new_account_reauthentication_path)
    delete destroy_user_session_path
    get user_google_oauth2_omniauth_callback_path
    expect(response).to redirect_to(account_root_path)
    delete destroy_user_session_path
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
    get user_google_oauth2_omniauth_callback_path
    expect(response).to redirect_to(new_user_session_path)
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
  it "garde le suivi accessible après clôture et expire le lien" do
    user = create(:user)
    record = Privacy.request!(user: user, kind: "erasure", details: "Demande")
    token = record.signed_id(purpose: :privacy_receipt, expires_in: 1.hour)
    login user
    user.update!(status: "anonymized")
    user.login_sessions.active.update_all(revoked_at: Time.current)
    get privacy_receipt_path(receipt_token: token)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(user.email)
    expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
    travel 2.hours do
      get privacy_receipt_path(receipt_token: token)
      expect(response).to have_http_status(:not_found)
    end
  end
  it "nettoie une image, la réserve au brouillon puis la retire au reset" do
    login admin
    post admin_studio_index_path, params: { operation: "upload", image: Rack::Test::UploadedFile.new(Rails.root.join("app/assets/images/seos-logo.png"), "image/png") }
    expect(response).to have_http_status(:see_other)
    asset = StudioAsset.last
    expect(asset.image.blob.content_type).to eq("image/jpeg")
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:ok)
    delete destroy_user_session_path
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:not_found)
    version = Studio.change!(actor: admin, name: "Image", settings: { "pages" => { "home" => { "image" => "asset:#{asset.id}", "alt" => "Une image de recette", "separator" => "wave_single", "animated" => true } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette") }
    get root_path
    expect(response.body).to include("Une image de recette", "studio-motion")
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:ok)
    reset = Studio.change!(actor: admin, name: "Défaut", settings: {}, source: version, reset: "site")
    %w[validate publish].each { |action| Studio.transition!(version: reset, actor: admin, action: action, reason: "Recette") }
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:not_found)
  end
end
