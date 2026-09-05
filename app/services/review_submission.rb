class ReviewSubmission
  def self.call(request:, actor:, attributes:, ratings:)
    raise Pundit::NotAuthorizedError unless request.participant?(actor)
    request.with_lock do
      raise Exchanges::Invalid, "L’échange doit être confirmé par les deux participants" unless request.completed?
      raise Exchanges::Invalid, "Le délai de 30 jours est dépassé" unless request.completed_at >= 30.days.ago
      criteria = ReviewCriterion.applicable(request, actor).to_a
      raise Exchanges::Invalid, "Répondez à tous les critères, ou choisissez Non applicable" unless ratings.keys.sort == criteria.map { |criterion| criterion.id.to_s }.sort
      review = request.reviews.create!(attributes.merge(author: actor, reviewee: request.other(actor), reveal_at: 14.days.from_now))
      criteria.each do |criterion|
        value = ratings.fetch(criterion.id.to_s)
        review.review_ratings.create!(review_criterion: criterion, label_snapshot: criterion.label,
          not_applicable: value == "na", rating: value == "na" ? nil : Integer(value, exception: false))
      end
      request.reviews.update_all(reveal_at: Time.current) if request.reviews.count == 2
      Notification.notify!(user: request.other(actor), key: "review:#{review.id}", title: "Un avis a été déposé pour votre échange", request: request)
      review
    end
  end
end
