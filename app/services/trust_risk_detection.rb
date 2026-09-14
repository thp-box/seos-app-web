class TrustRiskDetection
  def self.call(user)
    requests = ServiceRequest.participating(user).completed.where(completed_at: 30.days.ago..)
    pairs = requests.pluck(:requester_id, :provider_id).map { |ids| (ids - [ user.id ]).first }.tally
    referrals = Referral.where(referrer: user).where(claimed_at: 1.day.ago..)
    downstream = Referral.valid_support.where(referrer: user).pluck(:referred_user_id)
    visited = [ user.id ]
    cycle = false
    5.times do
      break if downstream.empty?
      if downstream.include?(user.id)
        cycle = true
        break
      end
      visited |= downstream
      downstream = Referral.valid_support.where(referrer_id: downstream).pluck(:referred_user_id).uniq - (visited - [ user.id ])
    end
    signals = {
      "exchange_burst" => requests.where(completed_at: 1.day.ago..).count,
      "repeated_pair" => pairs.values.max || 0,
      "referral_burst" => referrals.count,
      "referral_cycle" => cycle ? 1 : 0
    }
    thresholds = { "exchange_burst" => 10, "repeated_pair" => 5, "referral_burst" => 5, "referral_cycle" => 1 }
    signals.each do |signal, count|
      next if count < thresholds.fetch(signal)
      # One review per retention window, including dismissed false positives.
      next if TrustRiskAssessment.where(user: user, signal: signal).where("expires_at > ?", Time.current).exists?
      TrustRiskAssessment.create_or_find_by!(user: user, signal: signal, status: "open") do |record|
        record.assign_attributes(evidence_count: count, expires_at: 30.days.from_now)
      end
    end
  end
end
