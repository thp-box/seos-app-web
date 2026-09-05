module Account
  class PointsController < BaseController
    def show
      @account = PointAccount.find_by(user: current_user)
      @page = [ params[:page].to_i, 1 ].max
      scope = PointEntry.joins(:point_operation).where(point_account: @account, point_operations: { status: "committed" })
      @total = scope.count
      @entries = scope.includes(point_operation: :point_rule_version).order(id: :desc).limit(20).offset((@page - 1) * 20)
      @claims = PointRewardClaim.where(user: current_user).order(id: :desc).limit(20)
      @rule = PointRuleVersion.current("engagement")
      @level = @rule ? Points::Rewards.level(current_user, @rule) : "bronze"
    end

    def create
      case params[:operation]
      when "welcome"
        Points::Rewards.welcome!(current_user)
      when "claim"
        raise Exchanges::Invalid, "La récompense de chaîne suit maintenant la confirmation du bénéficiaire." if params[:kind] == "chain"
        Points::Rewards.submit!(user: current_user, kind: params[:kind], evidence: params[:evidence])
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to account_points_path, notice: "Votre demande a été enregistrée.", status: :see_other
    end
  end
end
