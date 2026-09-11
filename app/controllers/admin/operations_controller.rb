require "csv"
module Admin
  class OperationsController < BaseController
    def index
      @resources = OperationsCatalogue.visible_to(current_user)
      raise Pundit::NotAuthorizedError if @resources.empty?
      @kind = params[:resource].presence || @resources.keys.first
      @model, = @resources.fetch(@kind) { raise Pundit::NotAuthorizedError }
      records = @model.order(id: :desc)
      records = records.where(id: params[:q].to_s.delete_prefix("#")) if params[:q].present?
      @count = records.count
      @records = records.limit(100)
      @operations = BulkOperation.order(id: :desc).limit(20) if current_user.permission?("operations.manage")
      if params[:format] == "csv"
        raise Exchanges::Invalid, "Un motif est requis pour exporter." if params[:reason].blank?
        AuditLog.create!(actor: current_user, target: current_user, action: "operations.export", reason: params[:reason])
        send_data CSV.generate { |csv| csv << %w[id status created_at]; @records.each { |row| csv << [ row.id, row.attributes["status"], row.created_at ] } }, filename: "#{@kind}.csv", type: "text/csv"
      end
    end
    def create
      case params[:operation]
      when "preview"
        Operations.preview!(actor: current_user, ids: params[:ids].to_s.split(/[\s,]+/), reason: params[:reason])
      when "execute"
        Operations.execute!(operation: BulkOperation.find(params[:record_id]), actor: current_user)
      when "crawlers"
        raise Pundit::NotAuthorizedError unless current_user.super_admin? && current_user.permission?("seo.manage")
        CrawlerPolicy.transaction do
          policy = CrawlerPolicy.create!(author: current_user, search_enabled: params[:search_enabled] == "1", training_enabled: params[:training_enabled] == "1")
          AuditLog.create!(actor: current_user, target: policy, action: "seo.crawlers", reason: params[:reason])
        end
      when "block"
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
        raise Exchanges::Invalid, "Adresse invalide." unless params[:email].to_s.match?(URI::MailTo::EMAIL_REGEXP)
        raise Exchanges::Invalid, "Une adresse administrative ne peut pas être bloquée." if User.where(email: params[:email].strip.downcase, role: %w[admin super_admin]).exists?
        LoginBlock.transaction do
          record = LoginBlock.create!(email_digest: LoginBlock.digest(params[:email]), actor: current_user, reason: params[:reason], expires_at: params[:expires_at])
          AuditLog.create!(actor: current_user, target: record, action: "operations.block", reason: params[:reason])
        end
      else raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_operations_path, notice: "Action enregistrée.", status: :see_other
    end
    def user
      raise Pundit::NotAuthorizedError unless current_user.permission?("users.read")
      @user = User.find(params[:id])
      if request.post?
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
        AuditLog.create!(actor: current_user, target: @user, action: "user.sensitive_reveal", reason: params[:reason])
        @revealed = true
      end
    end
  end
end
