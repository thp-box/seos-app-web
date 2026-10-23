module Admin
  class DashboardController < BaseController
    def show
      @activity = AdminActivity.new(period: params[:period], super_admin: current_user.super_admin?)
      load_audit_logs if current_user.permission?("audit.read")
    end

    private

    def load_audit_logs
      @audit_page = [ params[:audit_page].to_i, 1 ].max
      logs = AuditLog.includes(:actor).order(id: :desc)
      logs = logs.where.not("action LIKE ?", "trust.risk.%") unless current_user.permission?("trust.risk")
      logs = logs.where.not("action LIKE ?", "points.%") unless current_user.permission?("points.read")
      logs = logs.where.not("action LIKE ?", "organization.legal.%") unless current_user.permission?("organizations.legal")
      logs = logs.where(action: params[:audit_event]) if params[:audit_event].present?
      @audit_total = logs.count
      @audit_logs = logs.limit(20).offset((@audit_page - 1) * 20)
    end
  end
end
