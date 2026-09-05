module Account
  class CommunityController < BaseController
    def show
      @achievements = Achievement.where(active: true).order(:position, :id)
      @records = UserAchievement.where(user: current_user).includes(:achievement).order(id: :desc).limit(50)
      @testimonials = Testimonial.where(user: current_user).order(id: :desc).limit(20)
      @listings = Listing.public_candidates.includes(:category, :organization, user: :profile).select { |listing| ListingPolicy.new(current_user, listing).update? && listing.publicly_visible? }
      @tops = TopListingRequest.where(user: current_user).includes(:listing).order(id: :desc).limit(20)
      @rule = PointRuleVersion.current("engagement")
    end

    def create
      case params[:operation]
      when "quest"
        Achievements.submit!(user: current_user, achievement: Achievement.find(params[:achievement_id]), evidence: params[:evidence], proof: params[:proof])
      when "top"
        Community.request_top!(user: current_user, listing: Listing.find(params[:listing_id]))
      when "withdraw_top"
        record = TopListingRequest.find(params[:record_id])
        raise Pundit::NotAuthorizedError unless record.user_id == current_user.id
        record.update!(status: "withdrawn")
      when "testimonial"
        Community.testimonial!(user: current_user, attributes: params.permit(:kind, :quote, :transcript, :display_name_snapshot, :public_location_snapshot).to_h, consent: params[:consent], video: params[:video])
      when "withdraw_testimonial"
        Community.withdraw!(record: Testimonial.find(params[:record_id]), user: current_user)
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to account_community_path, notice: "Votre demande a été enregistrée.", status: :see_other
    end
  end
end
