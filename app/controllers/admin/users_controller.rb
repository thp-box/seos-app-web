module Admin
  class UsersController < BaseController
    def index
      authorize :administration, :users?
      @users = User.order(id: :desc)
      @users = @users.where(role: params[:role]) if User.roles.key?(params[:role])
      @users = @users.where(status: params[:status]) if User.statuses.key?(params[:status])
      @users = @users.where(id: params[:q].to_s.delete_prefix("#")) if params[:q].present?
      @page = [ params[:page].to_i, 1 ].max
      @total = @users.count
      @users = @users.limit(20).offset((@page - 1) * 20)
    end
  end
end
