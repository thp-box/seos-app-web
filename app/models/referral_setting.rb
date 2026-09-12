class ReferralSetting < ApplicationRecord
  validates :minimum_age_days, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 36500 }
  def self.minimum_age_days = find_by(id: 1)&.minimum_age_days || 30
end
