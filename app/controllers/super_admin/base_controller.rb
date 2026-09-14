module SuperAdmin
  class BaseController < Admin::BaseController
    private

    def authorize_administration
      authorize :administration, :super_admin?
    end
  end
end
