class OrganizationInvitationsController < ApplicationController
  before_action :private_response
  before_action { response.headers["Referrer-Policy"] = "no-referrer" }
  def show
    if params[:invitation_token].present?
      invitation = OrganizationInvitation.find_by!(token_digest: Digest::SHA256.hexdigest(params[:invitation_token].to_s))
      raise Exchanges::Invalid, "Cette invitation a expiré ou a été retirée." unless invitation.available?
      session[:organization_invitation_id] = invitation.id
      return redirect_to(user_signed_in? ? organization_invitation_path : new_user_session_path, status: :see_other)
    end
    return redirect_to new_user_session_path unless user_signed_in?
    @invitation = OrganizationInvitation.find(session[:organization_invitation_id])
    raise Exchanges::Invalid, "Cette invitation est indisponible pour ce compte." unless @invitation.available? && @invitation.email == current_user.email.downcase
  end
  def create
    authenticate_user!
    return if performed?
    invitation = OrganizationInvitation.find(session[:organization_invitation_id])
    OrganizationWorkflow.accept!(invitation: invitation, actor: current_user)
    session.delete(:organization_invitation_id)
    redirect_to account_organization_path(invitation.organization), notice: "Vous avez rejoint l’équipe.", status: :see_other
  end
end
