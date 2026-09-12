module Account
  class TrustController < BaseController
    def show
      @snapshot = current_user.trust_profile&.trust_score_snapshot
      @snapshots = TrustScoreSnapshot.where(user: current_user).order(id: :desc).limit(20)
      @referrals = Referral.where(referred_user: current_user).order(:position)
      scope = Referral.where(referrer: current_user)
      @total = scope.count
      @qualified_count = scope.valid_support.where.not(qualified_at: nil).count
      @page = [ params[:page].to_i, 1 ].max
      @sponsorships = scope.includes(referred_user: :profile).order(id: :desc).limit(20).offset((@page - 1) * 20)
      @referral_link = ReferralLink.find_by(owner: current_user)
      @minimum_age_days = ReferralSetting.minimum_age_days
      @appeals = TrustAppeal.where(user: current_user).order(id: :desc).limit(20)
      @events = TrustEvent.where(subject: current_user).order(id: :desc).limit(50)
    end

    def create
      case params[:operation]
      when "issue"
        Referrals.link_for!(current_user)
        show
        return render :show, status: :created
      when "claim"
        Referrals.claim!(current_user, params[:referral_codes])
      when "primary"
        Referrals.primary!(current_user, Referral.where(referred_user: current_user).find(params[:referral_id]))
      when "object"
        Referrals.object!(current_user, Referral.where(referrer: current_user).find(params[:referral_id]), params[:reason])
      when "appeal"
        source = if params[:referral_id].present?
          { referral: Referral.where(referred_user: current_user).find(params[:referral_id]) }
        else
          { trust_score_snapshot: TrustScoreSnapshot.where(user: current_user).find(params[:snapshot_id]) }
        end
        TrustAppeal.create!(**source, user: current_user, statement: params[:statement], response_due_at: 7.days.from_now)
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to account_trust_path, notice: "Votre demande a été enregistrée.", status: :see_other
    end
  end
end
