module Admin
  class DashboardController < BaseController
    def show
      @activity = AdminActivity.new(period: params[:period], super_admin: current_user.super_admin?)
    end
  end
end
