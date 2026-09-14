class GeocodeListingJob < ApplicationJob
  def perform(listing)
    return unless listing.published? && !listing.service_location_mode_remote? && listing.city.present?
    city = listing.city
    coordinates = PublicGeocoding.coordinates(city)
    return unless coordinates&.size == 2
    listing.with_lock do
      return unless listing.published? && !listing.service_location_mode_remote? && listing.city == city
      listing.update!(latitude: coordinates[0].round(2), longitude: coordinates[1].round(2))
    end
  end
end
