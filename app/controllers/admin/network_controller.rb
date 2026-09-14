module Admin
  class NetworkController < BaseController
    before_action do
      raise Pundit::NotAuthorizedError unless %w[organizations.read organizations.manage organizations.legal missions.manage partnerships.manage].any? { |permission| current_user.permission?(permission) }
    end
    def index
      prepare_sections
      @section = params[:section].presence_in(@sections.keys) || "organizations"
      return if @section == "settings"

      model, title_column, statuses = resources.fetch(@section)
      scope = model.all
      if @section == "organizations" && %w[community_mission partnership].include?(params[:request_kind])
        legacy_kind = params[:request_kind] == "community_mission" ? "association" : %w[company micro_company institution collective]
        scope = scope.where(request_kind: params[:request_kind]).or(scope.where(request_kind: nil, kind: legacy_kind))
      end
      @counts = scope.group(:status).count
      @status = params[:status].presence_in(statuses)
      scope = scope.where(status: @status) if @status
      @query = params[:q].to_s.strip.first(120)
      if @query.present?
        scope = @query.match?(/\A#?\d+\z/) ? scope.where(id: @query.delete_prefix("#")) : scope.where("#{title_column} LIKE ?", "%#{model.sanitize_sql_like(@query)}%")
      end
      @total = scope.count
      @page = [ [ params[:page].to_i, 1 ].max, [ (@total / 20.0).ceil, 1 ].max ].min
      @records = scope.order(Arel.sql("CASE WHEN status IN ('pending', 'pending_review') THEN 0 ELSE 1 END"), updated_at: :desc, id: :desc).limit(20).offset((@page - 1) * 20)
      @records = @records.includes(:organization) unless @section == "organizations"
    end

    def show
      prepare_sections
      @section = params[:section].presence || "organizations"
      raise Pundit::NotAuthorizedError unless @sections.key?(@section) && @section != "settings"
      @record = resources.fetch(@section).first.find(params[:id])
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
        prepare_sections
        @section = "organizations"
        @record = @revealed
        return render :show
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
      section = params[:operation].start_with?("partnership") ? "partnerships" : (params[:operation].start_with?("mission") ? "missions" : (params[:operation] == "flag" ? "settings" : "organizations"))
      record_id = params[:record_id].presence || (defined?(record) && record&.id) || (defined?(mission) && mission&.id)
      destination = record_id && section != "settings" ? admin_network_path(record_id, section: section) : admin_network_index_path(section: section)
      redirect_to destination, notice: "Décision enregistrée.", status: :see_other
    end

    private

    def prepare_sections
      @sections = { "organizations" => "Demandes de structures" }
      @sections["partnerships"] = "Partenariats" if current_user.permission?("partnerships.manage")
      @sections["missions"] = "Missions" if current_user.permission?("missions.manage")
      @sections["settings"] = "Parcours publics" if current_user.super_admin?
    end

    def resources
      {
        "organizations" => [ Organization, "name", Organization.statuses.keys ],
        "partnerships" => [ Partnership, "public_title", %w[draft pending_review published archived] ],
        "missions" => [ VolunteerMission, "title", %w[draft pending_review published paused archived] ]
      }
    end
  end
end
