module Account
  class ChainsController < BaseController
    def index
      @chains = HelpChain.where(id: ChainService.where("provider_id = :id OR beneficiary_id = :id", id: current_user.id).select(:help_chain_id)).or(HelpChain.where(creator: current_user)).includes(:creator, chain_services: [ :provider, :beneficiary ]).order(id: :desc).limit(50)
    end

    def show
      @chain = HelpChain.find(params[:id])
      raise Pundit::NotAuthorizedError unless @chain.participant?(current_user)
      @services = @chain.chain_services.includes(:provider, :beneficiary, :chain_rewards).order(:position)
    end

    def create
      chain = Chains.create!(actor: current_user, name: params[:name])
      redirect_to account_chain_path(chain), status: :see_other
    end

    def update
      @chain = HelpChain.find(params[:id])
      _service, token = Chains.invite!(chain: @chain, actor: current_user, description: params[:description])
      @invitation_url = chain_invitation_url(invitation_token: token)
      response.headers["Referrer-Policy"] = "no-referrer"
      render :invited
    end
  end
end
