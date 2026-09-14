module Account
  class UserBlocksController < BaseController
    def create
      request = ServiceRequest.participating(current_user).find(params[:service_request_id])
      UserBlock.find_or_create_by!(user: current_user, blocked_user: request.other(current_user))
      redirect_to account_service_request_path(request), notice: "Membre bloqué pour les prises de contact et messages.", status: :see_other
    end
    def destroy
      block = UserBlock.where(user: current_user).find(params[:id])
      block.destroy!
      redirect_to account_root_path, notice: "Blocage retiré.", status: :see_other
    end
  end
end
