class TrustProfile < ApplicationRecord
  belongs_to :user
  belongs_to :trust_score_snapshot

  # A version change hides stale projections until its asynchronous calculation finishes.
  def public_result
    snapshot = trust_score_snapshot
    snapshot.result if snapshot.trust_algorithm_version.status == "active"
  end
end
