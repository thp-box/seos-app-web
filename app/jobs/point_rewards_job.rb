class PointRewardsJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound
  def perform(user_id)
    Points::Rewards.sync!(User.find(user_id))
  rescue Exchanges::Invalid => error
    # Monthly caps defer the reward; the source remains available for the next maintenance pass.
    Rails.logger.info("Récompense Points Services différée : #{error.message}")
  end
end
