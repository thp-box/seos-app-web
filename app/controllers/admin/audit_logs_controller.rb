module Admin
  class AuditLogsController < BaseController
    def index
      authorize :administration, :audit?
      @page = [ params[:page].to_i, 1 ].max
      @logs = AuditLog.includes(:actor).order(id: :desc)
      @logs = @logs.where.not("action LIKE ?", "trust.risk.%") unless current_user.permission?("trust.risk")
      @logs = @logs.where.not("action LIKE ?", "points.%") unless current_user.permission?("points.read")
      @logs = @logs.where.not("action LIKE ?", "financial.%") unless current_user.permission?("financial.read")
      @logs = @logs.where(action: params[:event]) if params[:event].present?
      @total = @logs.count
      @logs = @logs.limit(20).offset((@page - 1) * 20)
    end
  end
end
