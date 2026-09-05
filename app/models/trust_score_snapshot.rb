class TrustScoreSnapshot < ApplicationRecord
  belongs_to :user
  belongs_to :trust_algorithm_version
  def readonly? = persisted?
end
