class TrustMaintenanceJob < ApplicationJob
  def perform
    Referrals.mature!
    TrustRiskAssessment.where("expires_at <= ?", Time.current).delete_all
    User.where(status: "active").find_each do |user|
      TrustRiskDetection.call(user)
      TrustRecalculationJob.perform_later(user.id)
    end
  end
end
