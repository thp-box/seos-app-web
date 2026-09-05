module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :private_response
    before_action :authorize_administration
    before_action :require_recent_authentication
    after_action :verify_authorized
    layout "admin"

    private

    def authorize_administration
      authorize :administration, :show?
    end
  end
end
