module Account
  class TrustController < BaseController
    def show
      @snapshot = current_user.trust_profile&.trust_score_snapshot
      @snapshots = TrustScoreSnapshot.where(user: current_user).order(id: :desc).limit(20)
      @referrals = Referral.where(referred_user: current_user).order(:position)
      @sponsorships = Referral.where(referrer: current_user).order(id: :desc).limit(30)
      @codes = ReferralCode.where(owner: current_user).order(id: :desc).limit(10)
      @appeals = TrustAppeal.where(user: current_user).order(id: :desc).limit(20)
      @events = TrustEvent.where(subject: current_user).order(id: :desc).limit(50)
    end

    def create
      case params[:operation]
      when "issue"
        @issued_code = Referrals.issue!(current_user)
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
