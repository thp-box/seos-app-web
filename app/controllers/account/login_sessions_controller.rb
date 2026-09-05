module Account
  class LoginSessionsController < BaseController
    def index
      @sessions = current_user.login_sessions.active.order(created_at: :desc)
    end

    def destroy
      login_session = current_user.login_sessions.find(params[:id])
      login_session.revoke!
      redirect_to account_login_sessions_path, notice: "Session révoquée.", status: :see_other
    end
  end
end
