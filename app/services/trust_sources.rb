class TrustSources
  # Only revealed structured data enters the projection; free text and reports never do.
  def self.sync!(user)
    ServiceRequest.participating(user).completed.includes(:listing, reviews: { review_ratings: :review_criterion }).find_each do |request|
      next unless request.completed_at && request.requester_confirmed_at && request.provider_confirmed_at
      TrustEvent.create_or_find_by!(source_key: "exchange:#{request.id}:#{user.id}") do |event|
        event.assign_attributes(subject: user, actor: request.other(user), service_request: request, category: request.listing.category,
          source: request, dimension: "reliability", event_kind: "exchange", normalized_value: 1, occurred_at: request.completed_at)
      end
      request.reviews.select { |review| review.reviewee_id == user.id && review.revealed? }.each do |review|
        review.review_ratings.each do |rating|
          dimension = rating.dimension_snapshot
          next if rating.not_applicable? || !TrustEvent::DIMENSIONS.include?(dimension)
          TrustEvent.create_or_find_by!(source_key: "rating:#{rating.id}") do |event|
            event.assign_attributes(subject: user, actor: review.author, service_request: request, category: request.listing.category,
              source: review, dimension: dimension, event_kind: "review", normalized_value: (rating.rating - 1) / 4.0, occurred_at: request.completed_at)
          end
        end
      end
    end
  end
end
