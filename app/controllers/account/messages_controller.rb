module Account
  class MessagesController < BaseController
    def create
      request = ServiceRequest.participating(current_user).find(params[:service_request_id])
      values = params.require(:message).permit(:body, :delivery_key, :attachment)
      Exchanges.message!(request: request, actor: current_user, body: values[:body], key: values[:delivery_key], upload: values[:attachment])
      redirect_to account_service_request_path(request, anchor: "conversation"), status: :see_other
    end
  end
end
