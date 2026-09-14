module Admin
  class PrivacyController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.permission?("privacy.manage") || current_user.permission?("privacy.rules") }
    def index
      @requests = DataRequest.includes(:user, :provider_erasure_tasks).order(:response_due_at).limit(100) if current_user.permission?("privacy.manage")
      @policies = RetentionPolicyVersion.order(id: :desc).limit(30) if current_user.permission?("privacy.rules")
      @runs = PrivacyRun.order(id: :desc).limit(30) if current_user.permission?("privacy.rules")
    end
    def create
      case params[:operation]
      when "review" then Privacy.review!(request: DataRequest.find(params[:record_id]), actor: current_user, response: params[:response])
      when "execute" then Privacy.execute!(request: DataRequest.find(params[:record_id]), actor: current_user)
      when "export" then Privacy.export!(request: DataRequest.find(params[:record_id]), actor: current_user)
      when "provider"
        raise Pundit::NotAuthorizedError unless current_user.permission?("privacy.manage")
        task = ProviderErasureTask.find(params[:record_id])
        task.with_lock do
          raise Exchanges::Invalid, "Documentez la confirmation du prestataire." unless params[:response].present?
          task.update!(status: "completed", response: params[:response].to_s.first(3000), completed_at: Time.current)
          AuditLog.create!(actor: current_user, target: task, action: "privacy.provider", reason: params[:reason])
        end
      when "policy"
        raise Pundit::NotAuthorizedError unless current_user.super_admin? && current_user.permission?("privacy.rules")
        rules = if params[:rules].is_a?(ActionController::Parameters)
          params[:rules].permit(*RetentionPolicyVersion::PURPOSES).to_h.transform_values { |value| Integer(value, exception: false) }
        else
          JSON.parse(params[:rules].to_s) rescue nil
        end
        RetentionPolicyVersion.transaction do
          policy = RetentionPolicyVersion.create!(name: params[:name], rules: rules, effective_at: params[:effective_at], expires_at: params[:expires_at], created_by: current_user, legal_reviewed_at: params[:legal_reviewed] == "1" ? Time.current : nil)
          AuditLog.create!(actor: current_user, target: policy, action: "privacy.policy.draft", reason: "Proposition de durées par finalité")
        end
      when "simulate", "publish"
        Retention.policy!(policy: RetentionPolicyVersion.find(params[:record_id]), actor: current_user, action: params[:operation], reason: params[:reason])
      when "preview_purge" then Retention.preview!(actor: current_user, reason: params[:reason])
      when "purge" then Retention.execute!(run: PrivacyRun.find(params[:record_id]), actor: current_user)
      else raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_privacy_index_path, notice: "Action enregistrée.", status: :see_other
    end
  end
end
