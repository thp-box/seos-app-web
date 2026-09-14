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
    end

    def show
      @user = User.includes(:profile, trust_profile: { trust_score_snapshot: :trust_algorithm_version }).find(params[:id])
      @listing_counts = @user.listings.group(:status).count
      @reviews = Review.where(reviewee: @user).where("reveal_at <= ?", Time.current).includes(:review_ratings, author: :profile).order(id: :desc)
      @total = @reviews.count
      @page = [ [ params[:page].to_i, 1 ].max, [ (@total / 20.0).ceil, 1 ].max ].min
      @reviews = @reviews.limit(20).offset((@page - 1) * 20)
    end

    def update
      show
      if params[:operation] == "review"
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
      redirect_to admin_user_path(@user), notice: "Décision enregistrée et journalisée.", status: :see_other
    end
  end
end
