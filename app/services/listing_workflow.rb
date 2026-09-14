class ListingWorkflow
  def self.call(listing:, actor:, action:)
    raise Pundit::NotAuthorizedError unless ListingPolicy.new(actor, listing).update?
    listing.with_lock do
      previous = listing.status
      case action
      when "publish"
        raise Exchanges::Invalid, "Cette annonce attend une décision de modération" if listing.moderation_hold?
        raise Exchanges::Invalid, "Cette annonce ne peut plus être publiée" unless %w[draft paused pending_review].include?(previous)
        unless listing.valid?(listing.category&.sensitive? ? :moderated_publication : :publication)
          raise ActiveRecord::RecordInvalid, listing
        end
        listing.status = listing.category.sensitive? ? "pending_review" : "published"
        listing.moderation_hold = listing.category.sensitive?
        listing.published_at ||= Time.current if listing.published?
      when "pause"
        raise Exchanges::Invalid, "L’annonce n’est pas publiée" unless listing.published?
        listing.status = "paused"
      when "close", "remove"
        listing.status = action == "close" ? "closed" : "removed"
        listing.public_send(action == "close" ? "closed_at=" : "removed_at=", Time.current)
      else
        raise Exchanges::Invalid, "Action inconnue"
      end
      listing.save!
      AuditLog.create!(actor: actor, target: listing, action: "listing.#{action}", reason: "Gestion de l’annonce", metadata: { from: previous, to: listing.status })
    end
    GeocodeListingJob.perform_later(listing) if listing.published? && !listing.service_location_mode_remote? && listing.latitude.nil?
    listing
  end
end
