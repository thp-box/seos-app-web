module Admin
  class CommunityController < BaseController
    TABS = %w[quests proofs highlights testimonials chains settings].freeze
    before_action do
      raise Pundit::NotAuthorizedError unless %w[community.read community.manage community.rules].any? { |permission| current_user.permission?(permission) }
    end
    def index
      @tab = params[:tab].presence_in(TABS) || "quests"
      unless current_user.permission?("community.read") || current_user.permission?("community.manage")
        @tab = "settings"
        @achievements = @records = @tops = @testimonials = @chains = []
        @quest_total = @quest_visible_total = @quest_archived_total = @quest_manual_total = 0
        return
      end
      load_quests
      @records = UserAchievement.includes(:achievement).order(id: :desc).limit(30)
      @tops = TopListingRequest.includes(:listing).order(id: :desc).limit(30)
      @testimonials = Testimonial.order(id: :desc).limit(30)
      @chains = HelpChain.order(id: :desc).limit(30)
    end
    def create
      case params[:operation]
      when "policy"
        raise Pundit::NotAuthorizedError unless current_user.super_admin? && current_user.permission?("community.rules")
        CommunityPolicyVersion.transaction do
          version = CommunityPolicyVersion.create!(params.permit(:urgent_days, :top_max_days).to_h.merge(created_by: current_user))
          AuditLog.create!(actor: current_user, target: version, action: "community.policy", reason: params[:reason])
        end
      when "quest", "quest_update"
        raise Pundit::NotAuthorizedError unless current_user.permission?("community.manage")
        Achievement.transaction do
          record = params[:operation] == "quest" ? Achievement.new(params.permit(:slug, :reward_key, :recurrence).to_h.merge(slug: params[:slug].presence || "quete-#{SecureRandom.hex(6)}", event_name: "manual")) : Achievement.find(params[:record_id])
          record.update!(params.permit(:name, :description, :active, :position, :icon, :accent, :animated))
          AuditLog.create!(actor: current_user, target: record, action: "community.quest.save", reason: params[:reason])
        end
      when "review_quest"
        Achievements.review!(record: UserAchievement.find(params[:record_id]), actor: current_user, decision: params[:decision], reason: params[:reason])
      when "review_top"
        Community.review_top!(record: TopListingRequest.find(params[:record_id]), actor: current_user, decision: params[:decision], reason: params[:reason], days: params[:days].to_i, position: params[:position].to_i)
      when "review_testimonial"
        Community.review_testimonial!(record: Testimonial.find(params[:record_id]), actor: current_user, decision: params[:decision], reason: params[:reason])
      when "chain"
        Chains.moderate!(chain: HelpChain.find(params[:record_id]), actor: current_user, status: params[:decision], reason: params[:reason])
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_community_index_path(**redirect_parameters), notice: "Décision enregistrée.", status: :see_other
    end

    private

    def load_quests
      base_scope = Achievement.all
      @quest_total = base_scope.count
      @quest_visible_total = base_scope.where(active: true).count
      @quest_archived_total = @quest_total - @quest_visible_total
      @quest_manual_total = base_scope.where(builtin: false).count
      @quest_query = params[:quest_q].to_s.strip.first(100)
      @quest_status = params[:quest_status].presence_in(%w[active archived]) || "all"

      scope = base_scope.order(:position, :id)
      if @quest_query.present?
        query = "%#{Achievement.sanitize_sql_like(@quest_query)}%"
        scope = scope.where("name LIKE :query OR description LIKE :query OR slug LIKE :query", query: query)
      end
      scope = scope.where(active: true) if @quest_status == "active"
      scope = scope.where(active: false) if @quest_status == "archived"

      @quest_filtered_total = scope.count
      @quest_pages = [ (@quest_filtered_total / 24.0).ceil, 1 ].max
      @quest_page = [ [ params[:quest_page].to_i, 1 ].max, @quest_pages ].min
      @achievements = scope.limit(24).offset((@quest_page - 1) * 24)
      @edited_quest = base_scope.find_by(id: params[:edit_quest]) if params[:edit_quest].present?
    end

    def tab_for_operation
      { "quest" => "quests", "quest_update" => "quests", "review_quest" => "proofs", "review_top" => "highlights", "review_testimonial" => "testimonials", "chain" => "chains", "policy" => "settings" }.fetch(params[:operation], "quests")
    end

    def redirect_parameters
      parameters = { tab: tab_for_operation }
      return parameters unless params[:operation] == "quest_update"

      parameters.merge(
        edit_quest: params[:record_id],
        quest_q: params[:quest_q].presence,
        quest_status: params[:quest_status].presence_in(%w[active archived]) || "all",
        quest_page: params[:quest_page],
        anchor: "quest-editor"
      )
    end
  end
end
