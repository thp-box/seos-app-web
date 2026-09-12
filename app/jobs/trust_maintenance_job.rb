class TrustMaintenanceJob < ApplicationJob
  def perform
    User.where(status: "active").where.not(pending_referral_link_id: nil).find_each { |user| Referrals.activate_pending!(user) }
    Referrals.mature!
    TrustRiskAssessment.where("expires_at <= ?", Time.current).delete_all
    User.where(status: "active").find_each do |user|
      TrustRiskDetection.call(user)
      TrustRecalculationJob.perform_later(user.id)
    end
  end
end
