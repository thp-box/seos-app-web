module Account
  class ReauthenticationsController < BaseController
    rate_limit to: 5, within: 5.minutes, only: :create, store: Rack::Attack.cache.store
    def new
    end

    def create
      if current_user.valid_password?(params[:password].to_s)
        current_login_session.update!(reauthenticated_at: Time.current)
        redirect_to(current_user.administrative? ? admin_root_path : account_root_path, status: :see_other)
      else
        flash.now[:alert] = "Mot de passe incorrect."
        render :new, status: :unprocessable_content
      end
    end
  end
end
