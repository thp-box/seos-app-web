module Account
  class OrganizationsController < BaseController
    def index
      @organizations = Organization.where(id: OrganizationMembership.active.where(user: current_user).select(:organization_id)).order(:name)
    end
    def show
      @organization = Organization.find_by!(slug: params[:slug])
      raise Pundit::NotAuthorizedError unless OrganizationPolicy.new(current_user, @organization).workspace?
      @memberships = @organization.organization_memberships.active.includes(user: :profile)
      @invitations = @organization.organization_invitations.order(id: :desc).limit(20)
      @missions = @organization.volunteer_missions.order(id: :desc)
      @partnerships = @organization.partnerships.order(id: :desc)
      @mission = params[:mission_id] ? @missions.find(params[:mission_id]) : @organization.volunteer_missions.new
      @partnership = params[:partnership_id] ? @partnerships.find(params[:partnership_id]) : @organization.partnerships.new
    end
    def create
      organization = OrganizationWorkflow.create!(actor: current_user, attributes: params.require(:organization).permit(:name, :slug, :kind, :description, :public_location, :legal_name, :registration_number, :legal_email).to_h)
      redirect_to account_organization_path(organization), notice: "Votre organisation est en attente de vérification.", status: :see_other
    end
    def update
      show
      case params[:operation]
      when "profile"
        OrganizationWorkflow.update!(organization: @organization, actor: current_user, attributes: params.require(:organization).permit(:name, :description, :public_location, :legal_name, :registration_number, :legal_email, :lock_version).to_h, logo: params[:logo])
      when "invite"
        token = OrganizationWorkflow.invite!(organization: @organization, actor: current_user, email: params[:email], role: params[:role])
        @invitation_url = organization_invitation_url(invitation_token: token)
        response.headers["Referrer-Policy"] = "no-referrer"
        return render :invited
      when "revoke_invitation"
        raise Pundit::NotAuthorizedError unless OrganizationPolicy.new(current_user, @organization).manage_team?
        invitation = @organization.organization_invitations.find(params[:record_id])
        invitation.with_lock do
          invitation.update!(revoked_at: Time.current)
          AuditLog.create!(actor: current_user, target: invitation, action: "organization.invitation.revoked", reason: "Invitation révoquée par l’équipe")
        end
      when "membership"
        OrganizationWorkflow.membership!(membership: @memberships.find(params[:record_id]), actor: current_user, role: params[:role], status: params[:status])
      when "mission"
        mission = params[:record_id].present? ? @missions.find(params[:record_id]) : @organization.volunteer_missions.new
        Missions.save!(mission: mission, actor: current_user, attributes: params.require(:mission).permit(*VolunteerMission::FIELDS).to_h, photos: params[:photos])
      when "mission_transition"
        Missions.transition!(mission: @missions.find(params[:record_id]), actor: current_user, status: params[:status], reason: params[:reason])
      when "partnership"
        record = params[:record_id].present? ? @partnerships.find(params[:record_id]) : @organization.partnerships.new
        PartnershipWorkflow.save!(record: record, actor: current_user, attributes: params.require(:partnership).permit(*Partnership::FIELDS).to_h, logo: params[:logo])
      when "partnership_transition"
        PartnershipWorkflow.transition!(record: @partnerships.find(params[:record_id]), actor: current_user, status: params[:status], reason: params[:reason])
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to account_organization_path(@organization), notice: "Modification enregistrée.", status: :see_other
    end
  end
end
