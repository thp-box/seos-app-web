class ProfilesController < ApplicationController
  def show
    @profile = Profile.visible.find_by!(public_slug: params[:public_slug])
    @listings = @profile.user.listings.public_candidates.select(&:publicly_visible?)
    @reviews = Review.revealed.where(reviewee: @profile.user).includes(:review_ratings, author: :profile).order(created_at: :desc).limit(30)
    @chains = HelpChain.where(creator: @profile.user).or(HelpChain.where(id: ChainService.where(provider: @profile.user).or(ChainService.where(beneficiary: @profile.user)).select(:help_chain_id))).includes(chain_services: [ :chain_rewards, { provider: :profile, beneficiary: :profile } ]).distinct.order(id: :desc)
    @canonical = profile_url(@profile)
  end
end
