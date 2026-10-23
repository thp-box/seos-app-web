module Admin
  class UsersController < BaseController
    before_action -> { authorize :administration, :users? }

    def index
      @users = User.left_joins(:profile).includes(:profile).order(id: :desc)
      @users = @users.where(role: params[:role]) if User.roles.key?(params[:role])
      @users = @users.where(status: params[:status]) if User.statuses.key?(params[:status])
      if params[:q].present?
        query = params[:q].to_s.strip.first(100)
        @users = query.match?(/\A#?\d+\z/) ? @users.where(id: query.delete_prefix("#")) : @users.where("profiles.display_name LIKE ?", "%#{User.sanitize_sql_like(query)}%")
      end
      @total = @users.count
      @page = [ [ params[:page].to_i, 1 ].max, [ (@total / 20.0).ceil, 1 ].max ].min
      @users = @users.limit(20).offset((@page - 1) * 20)
      return unless current_user.super_admin?

      user_ids = @users.map(&:id)
      @point_balances = PointAccount.where(user_id: user_ids).pluck(:user_id, :balance).to_h
      @point_adjustments = PointAdjustment.where(user_id: user_ids, point_operation_id: nil)
        .where("expires_at > ?", Time.current).order(id: :desc).group_by(&:user_id)
    end

    def show
      @user = User.includes(:profile, trust_profile: { trust_score_snapshot: :trust_algorithm_version }).find(params[:id])
      @point_account = PointAccount.for!(@user)
      @point_adjustments = PointAdjustment.where(user: @user, point_operation_id: nil).order(id: :desc).limit(5) if current_user.super_admin?
      @listing_counts = @user.listings.group(:status).count
      @chains = HelpChain.where(creator: @user).or(HelpChain.where(id: ChainService.where(provider: @user).or(ChainService.where(beneficiary: @user)).select(:help_chain_id))).includes(chain_services: [ :chain_rewards, { provider: :profile, beneficiary: :profile } ]).distinct.order(id: :desc)
      @reviews = Review.where(reviewee: @user).where("reveal_at <= ?", Time.current).includes(:review_ratings, author: :profile).order(id: :desc)
      @total = @reviews.count
      @page = [ [ params[:page].to_i, 1 ].max, [ (@total / 20.0).ceil, 1 ].max ].min
      @reviews = @reviews.limit(20).offset((@page - 1) * 20)
    end

    def update
      @user = User.includes(:profile).find(params[:id])
      case params[:operation]
      when "review"
        raise Pundit::NotAuthorizedError unless current_user.permission?("reports.manage")
        review = Review.where(reviewee: @user).where("reveal_at <= ?", Time.current).find(params[:review_id])
        attributes = case params[:decision]
        when "hide" then { removed_at: Time.current }
        when "restore" then { removed_at: nil }
        when "invalidate" then { invalidated_at: Time.current }
        else raise Exchanges::Invalid, "Décision inconnue."
        end
        Review.transaction do
          review.update!(attributes)
          AuditLog.create!(actor: current_user, target: review, action: "review.#{params[:decision]}", reason: params[:reason])
        end
      when "promote_admin"
        raise Pundit::NotAuthorizedError unless current_user.super_admin? && @user.member? && @user.active? && @user.id != current_user.id
        @user.with_lock do
          @user.update!(role: "admin")
          @user.login_sessions.active.update_all(revoked_at: Time.current)
          AuditLog.create!(actor: current_user, target: @user, action: "user.promoted_admin", reason: params[:reason])
        end
      when "point_preview"
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
        Points::Adjustments.preview!(user: @user, actor: current_user, amount: Integer(params[:amount], exception: false), reason: params[:reason])
      when "point_commit"
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
        adjustment = PointAdjustment.where(user: @user).find(params[:adjustment_id])
        Points::Adjustments.commit!(adjustment, actor: current_user)
      when "feature_chain"
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
        chain = member_chains.find(params[:chain_id])
        chain.update!(featured_on_home: params[:featured] == "1")
        AuditLog.create!(actor: current_user, target: chain, action: "chain.home_feature", reason: params[:featured] == "1" ? "Mise en avant sur l’accueil" : "Retrait de l’accueil")
      else
        raise Pundit::NotAuthorizedError unless current_user.permission?("users.moderate")
        @user.with_lock do
          raise Pundit::NotAuthorizedError unless @user.member? && @user.id != current_user.id
          desired = params[:status]
          raise Exchanges::Invalid, "Seuls les comptes actifs ou suspendus peuvent être modérés." unless %w[active suspended].include?(@user.status) && %w[active suspended].include?(desired)
          previous = @user.status
          @user.update!(status: desired)
          @user.login_sessions.active.update_all(revoked_at: Time.current) if desired == "suspended"
          AuditLog.create!(actor: current_user, target: @user, action: "user.#{desired}", reason: params[:reason], metadata: { from: previous, to: desired })
        end
      end
      redirect_to update_return_path, notice: "Décision enregistrée et journalisée.", status: :see_other
    end

    private

    def member_chains
      HelpChain.where(creator: @user).or(
        HelpChain.where(id: ChainService.where(provider: @user).or(ChainService.where(beneficiary: @user)).select(:help_chain_id))
      ).distinct
    end

    def update_return_path
      params[:return_to] == "members" ? admin_users_path(anchor: "member-#{@user.id}") : admin_user_path(@user)
    end
  end
end
