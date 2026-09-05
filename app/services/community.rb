class Community
  def self.request_top!(user:, listing:)
    request = TopListingRequest.new(user: user, listing: listing)
    raise Pundit::NotAuthorizedError unless ListingPolicy.new(user, listing).update?
    raise Exchanges::Invalid, "Atteignez le niveau Argent ou faites valider votre partage du mois." unless request.eligible?
    listing.with_lock do
      listing.top_listing_requests.where(status: "approved").where("ends_at <= ?", Time.current).update_all(status: "expired")
      request.save!
    end
    request
  end

  def self.review_top!(record:, actor:, decision:, reason:, days: 7, position: 1)
    raise Pundit::NotAuthorizedError unless actor.permission?("community.manage") && actor.id != record.user_id
    raise Exchanges::Invalid, "Décision invalide." unless %w[approved rejected withdrawn].include?(decision)
    record.with_lock do
      raise Exchanges::Invalid, "Cette demande n’est plus en attente." unless record.status == "pending" || (record.status == "approved" && decision == "withdrawn")
      if decision == "approved"
        raise Exchanges::Invalid, "L’annonce n’est plus éligible." unless record.eligible?
        raise Exchanges::Invalid, "Choisissez une durée autorisée par la politique et une position de 1 à 100." unless (1..CommunityPolicyVersion.current.top_max_days).cover?(days) && (1..100).cover?(position)
        record.assign_attributes(starts_at: Time.current, ends_at: days.days.from_now, position: position)
      end
      record.update!(status: decision, reason: reason, reviewed_by: actor)
      AuditLog.create!(actor: actor, target: record, action: "community.top.#{decision}", reason: reason)
      Notification.notify!(user: record.user, key: "top:#{record.id}:#{decision}", title: "Votre demande de mise en avant a été examinée.")
    end
  end

  def self.testimonial!(user:, attributes:, consent:, video: nil)
    Chains.active!(user)
    raise Exchanges::Invalid, "Votre accord distinct de publication est nécessaire." unless consent == "1"
    user.with_lock do
      record = Testimonial.create!(attributes.merge(user: user, consent_version: Testimonial::CONSENT_VERSION, consented_at: Time.current))
      SafeVideo.attach!(record.video, video) if record.kind == "video"
      record
    end
  end

  def self.review_testimonial!(record:, actor:, decision:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("community.manage") && actor.id != record.user_id
    raise Exchanges::Invalid, "Décision invalide." unless %w[published rejected reexamine removed].include?(decision)
    record.user.with_lock do
      record.reload
      allowed = { "published" => %w[submitted], "rejected" => %w[submitted], "reexamine" => %w[rejected], "removed" => %w[published submitted rejected] }
      raise Exchanges::Invalid, "Transition indisponible." unless allowed.fetch(decision).include?(record.status)
      if decision == "published"
        Chains.active!(record.user)
        claim = PointRewardClaim.find_by(user: record.user, kind: record.kind, period_key: "lifetime")
        claim ||= Points::Rewards.submit!(user: record.user, kind: record.kind, evidence: "Témoignage consenti n° #{record.id}")
        # Publication and payment are distinct reviews: reward permissions remain mandatory.
        record.point_reward_claim = claim
        record.published_at = Time.current
      end
      record.update!(status: decision == "reexamine" ? "submitted" : decision, decision: reason, reviewed_by: actor, removed_at: decision == "removed" ? Time.current : nil)
      AuditLog.create!(actor: actor, target: record, action: "community.testimonial.#{decision}", reason: reason)
      Notification.notify!(user: record.user, key: "testimonial:#{record.id}:#{AuditLog.maximum(:id)}", title: "Votre témoignage a été examiné.")
    end
  end

  def self.withdraw!(record:, user:)
    raise Pundit::NotAuthorizedError unless record.user_id == user.id
    record.with_lock do
      record.update!(status: "removed", removed_at: Time.current)
      AuditLog.create!(actor: user, target: record, action: "community.testimonial.withdraw", reason: "Retrait du consentement de publication")
    end
  end
end
