module Account
  class MissionApplicationsController < BaseController
    def index
      ids = OrganizationMembership.active.where(user: current_user, role: %w[owner manager]).joins(:organization).where.not(organizations: { status: "suspended" }).select(:organization_id)
      @applications = MissionApplication.where(user: current_user).or(MissionApplication.where(volunteer_mission: VolunteerMission.where(organization_id: ids))).includes(:volunteer_mission).order(id: :desc).limit(100)
    end
    def show
      @application = MissionApplication.find(params[:id])
      raise Pundit::NotAuthorizedError unless @application.visible_to?(current_user)
      @mission = @application.volunteer_mission
      @messages = @application.mission_messages.includes(user: :profile).order(:id).last(100)
    end
    def create
      application = Missions.apply!(mission: VolunteerMission.find_by!(slug: params[:mission_slug]), actor: current_user, message: params[:message], starts_on: params[:starts_on], ends_on: params[:ends_on])
      redirect_to account_mission_application_path(application), status: :see_other
    end
    def update
      show
      case params[:operation]
      when "message"
        Missions.message!(application: @application, actor: current_user, body: params[:body], key: params[:delivery_key])
      when "decision"
        Missions.decide!(application: @application, actor: current_user, status: params[:status], reason: params[:reason])
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to account_mission_application_path(@application), notice: "Action enregistrée.", status: :see_other
    end
  end
end
