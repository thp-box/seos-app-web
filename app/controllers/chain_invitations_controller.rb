class ChainInvitationsController < ApplicationController
  before_action :private_response
  before_action { response.headers["Referrer-Policy"] = "no-referrer" }

  def show
    if params[:invitation_token].present?
      service = ChainService.find_by!(invitation_token_digest: ChainService.digest(params[:invitation_token].to_s))
      raise Exchanges::Invalid, "Cette invitation est indisponible ou expirée." unless service.available?
      session[:chain_invitation_id] = service.id
      return redirect_to(user_signed_in? ? chain_invitation_path : new_user_session_path, status: :see_other)
    end
    return redirect_to new_user_session_path unless user_signed_in?
    @service = ChainService.find(session[:chain_invitation_id])
    raise Exchanges::Invalid, "Cette invitation est indisponible ou expirée." unless @service.available?
  end

  def create
    authenticate_user!
    return if performed?
    service = ChainService.find(session[:chain_invitation_id])
    Chains.confirm!(service: service, actor: current_user)
    session.delete(:chain_invitation_id)
    redirect_to account_chain_path(service.help_chain), notice: "Service confirmé. À vous de poursuivre la chaîne !", status: :see_other
  end
end
