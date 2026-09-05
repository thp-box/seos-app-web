module Users
  class SessionsController < Devise::SessionsController
    skip_before_action :verify_login_session, only: :create
    before_action :private_response
    def create
      reset_session
      super do |user|
        _record, token = LoginSession.issue!(user: user, user_agent: request.user_agent)
        session[:login_token] = token
      end
    end

    def destroy
      current_login_session&.revoke!
      super
      reset_session
    end
  end
end
