module Account
  class DashboardController < BaseController
    def show
      @organizations = current_user.organizations.where(status: :verified)
        .where(organization_memberships: { status: :active })
      @account = PointAccount.find_by(user: current_user)
      @entries = PointEntry.joins(:point_operation).where(point_account: @account, point_operations: { status: "committed" }).includes(:point_operation).order(id: :desc).limit(5)
      @rule = PointRuleVersion.current("engagement")
      @level = @rule ? Points::Rewards.level(current_user, @rule) : "bronze"
      @completed = Points::Rewards.transfers(current_user).count
      @next_level = @rule && (@level == "bronze" ? @rule.configuration["silver_after"] : @rule.configuration["gold_after"])
      @chain = HelpChain.where(id: ChainService.where("provider_id = :id OR beneficiary_id = :id", id: current_user.id).select(:help_chain_id)).or(HelpChain.where(creator: current_user)).order(id: :desc).first
      @services = @chain ? @chain.chain_services.includes(:provider, :beneficiary).order(:position).limit(4) : []
      @request = ServiceRequest.participating(current_user).includes(:listing, :provider, :requester).order(updated_at: :desc).first
    end
  end
end
