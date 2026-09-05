class PointMaintenanceJob < ApplicationJob
  def perform
    User.where(status: "active").find_each { |user| PointRewardsJob.perform_later(user.id) }
  end
end
