module Account
  class ReportsController < BaseController
    def new
      @target = target
    end
    def create
      record = target
      Report.create!(reporter: current_user, reportable: record, **params.require(:report).permit(:reason, :details).to_h.symbolize_keys)
      redirect_to account_root_path, notice: "Signalement reçu par l’équipe de modération.", status: :see_other
    end
    private
    def target
      type = params[:target_type]
      raise ActiveRecord::RecordNotFound unless Report::TARGETS.include?(type)
      record = type.constantize.find(params[:target_id])
      allowed = case record
      when Listing then record.publicly_visible?
      when Profile then Profile.visible.exists?(id: record.id)
      when Message then record.service_request.participant?(current_user)
      when ServiceRequest then record.participant?(current_user)
      when Comment then record.removed_at.nil? && record.listing.publicly_visible?
      when Review then record.revealed?
      end
      raise ActiveRecord::RecordNotFound unless allowed
      record
    end
  end
end
