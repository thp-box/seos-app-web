module Admin
  class PointsController < BaseController
    before_action :require_points_permission

    def index
      @operations = PointOperation.committed.order(id: :desc).limit(50) if current_user.permission?("points.read")
      @adjustments = PointAdjustment.order(id: :desc).limit(20) if current_user.permission?("points.adjust")
      @claims = PointRewardClaim.order(id: :desc).limit(30) if current_user.permission?("points.rewards")
      @versions = PointRuleVersion.order(id: :desc).limit(20) if current_user.permission?("points.rules")
    end

    def create
      case params[:operation]
      when "preview"
        Points::Adjustments.preview!(user: User.find(params[:user_id]), actor: current_user, amount: Integer(params[:amount], exception: false), reason: params[:reason])
      when "commit"
        Points::Adjustments.commit!(PointAdjustment.find(params[:record_id]), actor: current_user)
      when "reverse"
        Points::Ledger.reverse!(PointOperation.find(params[:record_id]), actor: current_user, reason: params[:reason])
      when "review"
        Points::Rewards.review!(PointRewardClaim.find(params[:record_id]), actor: current_user, decision: params[:decision], reason: params[:reason])
      when "version"
        raise Pundit::NotAuthorizedError unless current_user.super_admin? && current_user.permission?("points.rules")
        config = JSON.parse(params[:configuration].to_s) rescue nil
        PointRuleVersion.transaction do
          version = PointRuleVersion.create!(family: params[:family], name: params[:name], configuration: config, effective_at: params[:effective_at], created_by: current_user)
          AuditLog.create!(actor: current_user, target: version, action: "points.rules.create", reason: params[:reason])
        end
      when "simulate", "publish", "rollback"
        version = PointRuleVersion.find(params[:record_id])
        case params[:operation]
        when "simulate" then Points::Rules.simulate!(version, actor: current_user, reason: params[:reason])
        when "publish" then Points::Rules.publish!(version, actor: current_user, reason: params[:reason])
        when "rollback" then Points::Rules.rollback!(version, actor: current_user, reason: params[:reason])
        end
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_points_path, notice: "Action enregistrée.", status: :see_other
    end

    private

    def require_points_permission
      raise Pundit::NotAuthorizedError unless %w[points.read points.adjust points.rewards points.rules].any? { |permission| current_user.permission?(permission) }
    end
  end
end
