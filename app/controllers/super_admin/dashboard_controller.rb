module SuperAdmin
  class DashboardController < BaseController
    def show
      redirect_to admin_root_path
    end
  end
end
