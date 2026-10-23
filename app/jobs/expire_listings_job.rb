class ExpireListingsJob < ApplicationJob
  def perform
    Listing.published.where(expires_at: ..Time.current).find_each do |listing|
      listing.with_lock do
        next unless listing.published? && listing.expired?

        listing.update!(status: "paused", moderation_hold: false)
        Notification.notify!(user: listing.user, key: "listing-expired:#{listing.id}:#{listing.expires_at.to_i}",
          title: "Votre annonce est arrivée à échéance. Vous pouvez la réactiver pour un an.", category: "listings")
      end
    end
  end
end
