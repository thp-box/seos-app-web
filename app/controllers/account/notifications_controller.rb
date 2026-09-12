module Account
  class NotificationsController < BaseController
    def index
      @available_categories = current_user.notifications.distinct.pluck(:category)
      @category = params[:category] if Notification::CATEGORIES.key?(params[:category])
      scope = current_user.notifications
      scope = scope.where(category: @category) if @category
      @page = [ params[:page].to_i, 1 ].max
      @total = scope.count
      @unread_through = scope.unread.maximum(:id)
      @notifications = scope.includes(:service_request).order(id: :desc).limit(20).offset((@page - 1) * 20)
    end

    def counts
      render json: { categories: current_user.notifications.unread.group(:category).count,
        balance: PointAccount.find_by(user: current_user)&.balance || 0 }
    end

    def update
      current_user.notifications.find(params[:id]).update!(read_at: Time.current)
      redirect_to account_notifications_path(category: params[:category].presence), status: :see_other
    end

    def open
      notice = current_user.notifications.find(params[:id])
      notice.update!(read_at: Time.current) unless notice.read_at
      redirect_to helpers.notification_destination(notice), status: :see_other
    end

    def read_all
      raise Exchanges::Invalid, "Rubrique inconnue." if params[:category].present? && !Notification::CATEGORIES.key?(params[:category])
      scope = current_user.notifications.unread.where(id: ..params[:through_id].to_i)
      scope = scope.where(category: params[:category]) if Notification::CATEGORIES.key?(params[:category])
      scope.update_all(read_at: Time.current)
      redirect_to account_notifications_path(category: params[:category].presence), status: :see_other
    end

    def preferences
      current_user.update!(params.require(:user).permit(:email_notifications))
      redirect_to account_notifications_path, notice: "Préférence enregistrée.", status: :see_other
    end
  end
end
