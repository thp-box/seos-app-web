class Catalogue
  def self.call(params)
    params = params.with_indifferent_access if params.is_a?(Hash)
    scope = Listing.public_candidates.includes(:category, :organization, user: :profile)
    scope = scope.where("listings.title LIKE :q OR listings.description LIKE :q", q: "%#{Listing.sanitize_sql_like(params[:q].to_s.first(100))}%") if params[:q].present?
    %w[intent service_location_mode priority].each do |key|
      scope = scope.where(key => params[key]) if params[key].present?
    end
    modes = Array(params.key?(:exchange_modes) ? params[:exchange_modes] : params[:exchange_mode]).reject(&:blank?)
    scope = scope.where(exchange_mode: modes) if modes.any? || params.key?(:exchange_modes)
    maximum = Integer(params[:max_points], exception: false)
    scope = scope.where("listings.exchange_mode != 'points' OR listings.estimated_points <= ?", maximum) if maximum && (0...200).cover?(maximum)
    scope = scope.where("urgent_until > ?", Time.current) if params[:priority] == "urgent"
    selected_categories = Array(params.key?(:category_ids) ? params[:category_ids] : params[:category_id]).reject(&:blank?).map(&:to_s)
    if selected_categories.any?
      ids = Category.available.select { |category| category.lineage.any? { |ancestor| selected_categories.include?(ancestor.id.to_s) } }.map(&:id)
      scope = scope.where(category_id: ids)
    end
    records = scope.order(published_at: :desc, id: :desc).select(&:publicly_visible?)
    if params[:city].present? && params[:latitude].blank?
      city = params[:city].to_s.first(100).downcase
      records.select! { |listing| listing.service_location_mode_remote? || listing.city.to_s.downcase.include?(city) }
    end
    if params[:latitude].present? && params[:longitude].present? && params[:radius].present?
      lat, lon, radius = %i[latitude longitude radius].map { |key| Float(params[key], exception: false) }
      if lat && lon && radius && (-90..90).cover?(lat) && (-180..180).cover?(lon) && (1..300).cover?(radius)
        records.select! { |listing| listing.service_location_mode_remote? || (listing.public_coordinates && Geocoder::Calculations.distance_between([ lat, lon ], listing.public_coordinates, units: :km) <= radius) }
      else
        records = []
      end
    end
    records.sort_by! { |listing| placement = listing.top_placement; [ placement ? 0 : 1, placement&.position || 0 ] } unless params[:sort] == "oldest"
    records.reverse! if params[:sort] == "oldest"
    records
  end
end
