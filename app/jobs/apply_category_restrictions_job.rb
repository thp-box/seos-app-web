class ApplyCategoryRestrictionsJob < ApplicationJob
  def perform
    CategoryRestriction.effective.find_each do |restriction|
      Listing.published.includes(:category).find_each do |listing|
        next unless restriction.matches?(listing)
        listing.with_lock do
          next unless listing.published?
          listing.update!(status: restriction.existing_action == "pause" ? "paused" : "pending_review", moderation_hold: true)
          AuditLog.create!(actor: restriction.created_by, target: listing, action: "listing.restricted", reason: restriction.reason,
            metadata: { from: "published", to: listing.status })
          Notification.notify!(user: listing.user, key: "restriction:#{listing.id}:#{listing.lock_version}", title: "Une annonce a été mise en revue")
        end
      end
    end
  end
end
