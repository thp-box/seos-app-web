module Admin
  class AuditLogsController < BaseController
    def index
      authorize :administration, :audit?
      @page = [ params[:page].to_i, 1 ].max
      @logs = AuditLog.includes(:actor).order(id: :desc)
      @logs = @logs.where(action: params[:event]) if params[:event].present?
      @total = @logs.count
      @logs = @logs.limit(20).offset((@page - 1) * 20)
    end
  end
end
