class PublicGeocoding
  def self.coordinates(city)
    return if city.blank?
    Rails.cache.fetch([ "public-city", city.downcase ], expires_in: 30.days, skip_nil: true) do
      result = Geocoder.search(city, type: "municipality", limit: 1, autocomplete: 0).first&.coordinates
      result&.map { |coordinate| coordinate.round(2) }
    end
  end
end
