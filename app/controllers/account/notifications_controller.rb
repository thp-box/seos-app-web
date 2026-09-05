module Account
  class NotificationsController < BaseController
    def index
      @notifications = current_user.notifications.order(created_at: :desc).limit(100)
    end
    def update
      current_user.notifications.find(params[:id]).update!(read_at: Time.current)
      redirect_to account_notifications_path, status: :see_other
    end
    def preferences
      current_user.update!(params.require(:user).permit(:email_notifications))
      redirect_to account_notifications_path, notice: "Préférence enregistrée.", status: :see_other
    end
  end
end
