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
      missions = @organization.volunteer_missions
      @mission_counts = missions.group(:status).count
      @mission_total = @mission_counts.values.sum
      @mission_status = params[:mission_status].presence_in(%w[draft pending_review published paused archived])
      @mission_search = params[:mission_search].to_s.strip.first(150)
      filtered = @mission_status ? missions.where(status: @mission_status) : missions
      if @mission_search.present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@mission_search)}%"
        filtered = filtered.where("title LIKE :query OR public_location LIKE :query", query: pattern)
      end
      @mission_sort = params[:mission_sort].presence_in(%w[recent title starts_on]) || "recent"
      order = { "recent" => { updated_at: :desc, id: :desc }, "title" => { title: :asc, id: :desc }, "starts_on" => { starts_on: :asc, id: :desc } }.fetch(@mission_sort)
      @mission_matches = filtered.count
      @mission_pages = [ (@mission_matches / 15.0).ceil, 1 ].max
      @mission_page = [ [ params[:mission_page].to_i, 1 ].max, @mission_pages ].min
      @missions = filtered.order(order).limit(15).offset((@mission_page - 1) * 15)
      @mission_application_counts = MissionApplication.where(volunteer_mission_id: @missions.select(:id)).group(:volunteer_mission_id).count
      @partnerships = @organization.partnerships.order(id: :desc)
      @mission = params[:mission_id] ? missions.find(params[:mission_id]) : @organization.volunteer_missions.new
      @partnership = params[:partnership_id] ? @partnerships.find(params[:partnership_id]) : @organization.partnerships.new
    end
    def create
      organization = OrganizationWorkflow.create!(actor: current_user, attributes: params.require(:organization).permit(:name, :slug, :request_kind, :kind, :description, :public_location, :legal_name, :registration_number, :legal_email).to_h)
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
        @mission = params[:record_id].present? ? @organization.volunteer_missions.find(params[:record_id]) : @organization.volunteer_missions.new
        Missions.save!(mission: @mission, actor: current_user, attributes: params.require(:mission).permit(*VolunteerMission::FIELDS).to_h, photos: params[:photos])
      when "mission_transition"
        Missions.transition!(mission: @organization.volunteer_missions.find(params[:record_id]), actor: current_user, status: params[:status], reason: params[:reason])
      when "partnership"
        record = params[:record_id].present? ? @partnerships.find(params[:record_id]) : @organization.partnerships.new
        PartnershipWorkflow.save!(record: record, actor: current_user, attributes: params.require(:partnership).permit(*Partnership::FIELDS).to_h, logo: params[:logo])
      when "partnership_transition"
        raise Exchanges::Invalid, "Vous pouvez envoyer votre proposition à l’équipe SEOS pour validation." unless params[:status] == "pending_review"
        PartnershipWorkflow.transition!(record: @partnerships.find(params[:record_id]), actor: current_user, status: "pending_review", reason: "Proposition envoyée à SEOS par un membre de l’organisation")
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      tab = { "profile" => "profile", "membership" => "team", "revoke_invitation" => "team", "mission" => "missions", "mission_transition" => "missions", "partnership" => "partnerships", "partnership_transition" => "partnerships" }[params[:operation]]
      tracking = tab == "missions" ? { mission_search: @mission_search.presence, mission_status: @mission_status, mission_sort: @mission_sort, mission_page: @mission_page } : {}
      redirect_to account_organization_path(@organization, tab: tab, **tracking), notice: (params[:operation] == "partnership_transition" ? "Votre proposition a été envoyée à l’équipe SEOS. Elle est en attente de validation." : "Modification enregistrée."), status: :see_other
    rescue ActiveRecord::RecordInvalid, Exchanges::Invalid => error
      raise unless params[:operation] == "mission" && @mission

      @mission_editor = true
      @mission_error = error.is_a?(ActiveRecord::RecordInvalid) ? error.record.errors.full_messages.join(". ") : error.message
      render :show, status: :unprocessable_content
    end
  end
end
