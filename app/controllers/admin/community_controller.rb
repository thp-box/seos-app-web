module Admin
  class CommunityController < BaseController
    before_action do
      raise Pundit::NotAuthorizedError unless %w[community.read community.manage community.rules].any? { |permission| current_user.permission?(permission) }
    end
    def index
      unless current_user.permission?("community.read") || current_user.permission?("community.manage")
        @achievements = @records = @tops = @testimonials = @chains = []
        @versions = ChainRuleVersion.order(id: :desc).limit(20)
        return
      end
      @achievements = Achievement.order(:position, :id)
      @records = UserAchievement.includes(:achievement).order(id: :desc).limit(30)
      @tops = TopListingRequest.includes(:listing).order(id: :desc).limit(30)
      @testimonials = Testimonial.order(id: :desc).limit(30)
      @chains = HelpChain.order(id: :desc).limit(30)
      @versions = ChainRuleVersion.order(id: :desc).limit(20) if current_user.permission?("community.rules")
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
      when "version", "rollback"
        raise Pundit::NotAuthorizedError unless current_user.super_admin? && current_user.permission?("community.rules")
        ChainRuleVersion.transaction do
          attributes = if params[:operation] == "rollback"
            ChainRuleVersion.find(params[:record_id]).attributes.slice(*ChainRuleVersion::FIELDS).merge("effective_at" => params[:effective_at])
          else
            params.permit(*ChainRuleVersion::FIELDS).to_h
          end
          version = ChainRuleVersion.create!(attributes.merge(name: params[:name], created_by: current_user))
          AuditLog.create!(actor: current_user, target: version, action: "chain.rule.create", reason: params[:reason])
        end
      when "simulate", "publish"
        Chains.rule!(version: ChainRuleVersion.find(params[:record_id]), actor: current_user, action: params[:operation], reason: params[:reason])
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_community_index_path, notice: "Décision enregistrée.", status: :see_other
    end
  end
end
