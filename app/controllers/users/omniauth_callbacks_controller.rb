module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    before_action :private_response
    def google_oauth2
      raise ActiveRecord::RecordNotFound unless GoogleIdentity.enabled? || Rails.env.test?
      if current_user
        return require_recent_authentication unless current_login_session&.recently_authenticated?
      end
      user = GoogleIdentity.resolve!(auth: request.env["omniauth.auth"], user: current_user)
      pending = session.to_hash.slice("organization_invitation_id", "chain_invitation_id")
      current_login_session&.revoke!
      reset_session
      pending.each { |key, value| session[key] = value if value.is_a?(Integer) }
      _record, token = LoginSession.issue!(user: user, user_agent: request.user_agent)
      session[:login_token] = token
      sign_in :user, user, force: true
      redirect_to after_sign_in_path_for(user), status: :see_other
    end
    def failure
      redirect_to new_user_session_path, alert: "La connexion Google n’a pas abouti. Réessayez ou utilisez votre mot de passe.", status: :see_other
    end
  end
end
