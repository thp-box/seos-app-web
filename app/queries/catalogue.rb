class Catalogue
  def self.call(params)
    params = params.with_indifferent_access if params.is_a?(Hash)
    scope = Listing.public_candidates.includes(:category, :organization, user: :profile)
    scope = scope.where("listings.title LIKE :q OR listings.description LIKE :q", q: "%#{Listing.sanitize_sql_like(params[:q].to_s.first(100))}%") if params[:q].present?
    %w[intent exchange_mode service_location_mode category_id priority].each do |key|
      scope = scope.where(key => params[key]) if params[key].present?
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
    records.reverse! if params[:sort] == "oldest"
    records
  end
end
