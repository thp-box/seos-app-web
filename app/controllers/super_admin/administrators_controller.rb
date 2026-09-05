module SuperAdmin
  class AdministratorsController < BaseController
    rescue_from ArgumentError, ActiveRecord::RecordInvalid, with: :invalid_change

    def index
      @users = User.where(role: :admin).order(:id).limit(100)
      @selected = User.find_by(id: params[:user_id]) if params[:user_id].present?
    end

    def update
      user = User.find(params[:id])
      Administration::ChangeRole.call(actor: current_user, user: user, role: params[:role], reason: params[:reason])
      redirect_to super_admin_administrators_path(user_id: user.id), notice: "Rôle enregistré.", status: :see_other
    end

    private

    def invalid_change(exception)
      redirect_to super_admin_administrators_path, alert: exception.message, status: :see_other
    end
  end
end
