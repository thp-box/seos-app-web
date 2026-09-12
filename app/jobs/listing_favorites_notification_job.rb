class ListingFavoritesNotificationJob < ApplicationJob
  def perform(listing_id, version)
    listing = Listing.find_by(id: listing_id)
    return unless listing
    Favorite.where(listing: listing).where.not(user_id: listing.user_id).includes(:user).find_each do |favorite|
      Notification.notify!(user: favorite.user, key: "favorite:#{listing.id}:#{version}", title: "Une annonce de vos favoris a changé de disponibilité.", category: "favorites")
    end
  end
end
