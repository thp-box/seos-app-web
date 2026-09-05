module Admin
  class FinancialSupportController < BaseController
    before_action do
      raise Pundit::NotAuthorizedError unless current_user.permission?("financial.read") || current_user.permission?("financial.manage")
    end
    def index
      @contributions = FinancialContribution.order(id: :desc).limit(50)
    end
    def create
      case params[:operation]
      when "toggle"
        FinancialSupport.toggle!(actor: current_user, enabled: params[:enabled] == "1", reason: params[:reason], validations: params[:validations])
      when "refund", "reconcile"
        record = FinancialContribution.find(params[:record_id])
        FinancialSupport.public_send("#{params[:operation]}!", record: record, actor: current_user, reason: params[:reason])
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_financial_support_index_path, notice: "Action enregistrée.", status: :see_other
    end
  end
end
