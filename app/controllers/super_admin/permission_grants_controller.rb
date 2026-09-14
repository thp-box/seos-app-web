module SuperAdmin
  class PermissionGrantsController < BaseController
    rescue_from ArgumentError, ActiveRecord::RecordInvalid, with: :invalid_change

    def create
      user = User.find(params[:administrator_id])
      Administration::GrantPermission.call(actor: current_user, user: user, permission: params[:permission],
        reason: params[:reason], expires_at: Time.zone.parse(params[:expires_at].to_s))
      redirect_to super_admin_administrators_path(user_id: user.id), notice: "Permission attribuée.", status: :see_other
    end

    def destroy
      user = User.find(params[:administrator_id])
      grant = user.admin_permission_grants.find(params[:id])
      Administration::RevokePermission.call(actor: current_user, grant: grant, reason: params[:reason])
      redirect_to super_admin_administrators_path(user_id: user.id), notice: "Permission révoquée.", status: :see_other
    end

    private

    def invalid_change(exception)
      redirect_to super_admin_administrators_path, alert: exception.message, status: :see_other
    end
  end
end
