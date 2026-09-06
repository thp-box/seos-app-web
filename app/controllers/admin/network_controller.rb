module Admin
  class NetworkController < BaseController
    before_action do
      raise Pundit::NotAuthorizedError unless %w[organizations.read organizations.manage organizations.legal missions.manage partnerships.manage].any? { |permission| current_user.permission?(permission) }
    end
    def index
      @organizations = Organization.order(id: :desc).limit(50)
      @missions = VolunteerMission.includes(:organization).order(id: :desc).limit(50) if current_user.permission?("missions.manage")
      @partnerships = Partnership.includes(:organization).order(:position, :id).limit(50) if current_user.permission?("partnerships.manage")
    end
    def create
      case params[:operation]
      when "recover_owner"
        OrganizationWorkflow.recover_owner!(organization: Organization.find(params[:record_id]), actor: current_user, user: User.find(params[:user_id]), reason: params[:reason])
      when "review"
        OrganizationWorkflow.review!(organization: Organization.find(params[:record_id]), actor: current_user, status: params[:status], kind: params[:kind], reason: params[:reason])
      when "reveal"
        raise Pundit::NotAuthorizedError unless current_user.permission?("organizations.legal")
        @revealed = Organization.find(params[:record_id])
        AuditLog.create!(actor: current_user, target: @revealed, action: "organization.legal.reveal", reason: params[:reason])
        index
        return render :index
      when "mission"
        mission = params[:record_id].present? ? VolunteerMission.find(params[:record_id]) : Organization.find(params[:organization_id]).volunteer_missions.new
        Missions.save!(mission: mission, actor: current_user, attributes: params.require(:mission).permit(*VolunteerMission::FIELDS).to_h, photos: params[:photos])
      when "mission_transition"
        Missions.transition!(mission: VolunteerMission.find(params[:record_id]), actor: current_user, status: params[:status], reason: params[:reason])
      when "partnership"
        record = params[:record_id].present? ? Partnership.find(params[:record_id]) : Organization.find(params[:organization_id]).partnerships.new
        fields = Partnership::FIELDS + [ :position ]
        fields += [ :kind ] if current_user.super_admin?
        PartnershipWorkflow.save!(record: record, actor: current_user, attributes: params.require(:partnership).permit(*fields).to_h, logo: params[:logo])
      when "partnership_transition"
        PartnershipWorkflow.transition!(record: Partnership.find(params[:record_id]), actor: current_user, status: params[:status], reason: params[:reason])
      when "flag"
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
        raise Exchanges::Invalid, "Paramètre inconnu." unless %w[voyage_enabled partnerships_enabled].include?(params[:key])
        FeatureFlag.transaction do
          flag = FeatureFlag.find_or_initialize_by(key: params[:key])
          flag.update!(enabled: params[:enabled] == "1")
          AuditLog.create!(actor: current_user, target: flag, action: "organization.flag", reason: params[:reason])
        end
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_network_index_path, notice: "Décision enregistrée.", status: :see_other
    end
  end
end
