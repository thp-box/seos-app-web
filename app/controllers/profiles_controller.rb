class ProfilesController < ApplicationController
  def show
    @profile = Profile.visible.find_by!(public_slug: params[:public_slug])
    @listings = @profile.user.listings.public_candidates.select(&:publicly_visible?)
    @reviews = Review.revealed.where(reviewee: @profile.user).includes(:review_ratings, author: :profile).order(created_at: :desc).limit(30)
    @canonical = profile_url(@profile)
  end
end
