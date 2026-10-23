class FeatureFlag < ApplicationRecord
  validates :key, inclusion: { in: %w[public_map_enabled voyage_enabled] }, uniqueness: true
  def self.voyage_enabled? = find_by(key: "voyage_enabled")&.enabled != false
  def self.tile_url = ENV.fetch("MAP_TILE_URL", Rails.env.test? ? "" : "https://tile.openstreetmap.org/{z}/{x}/{y}.png")
  def self.map_enabled? = find_by(key: "public_map_enabled")&.enabled != false
end
