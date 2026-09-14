class TrustRecalculationJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id)
    user = User.find(user_id)
    user.with_lock do
      TrustSources.sync!(user)
      TrustAlgorithmVersion.where(status: %w[active shadow]).find_each do |version|
        result, contributions = TrustCalculator.new(user: user, version: version).call
        fingerprint = Digest::SHA256.hexdigest([ result, contributions ].to_json)
        snapshot = TrustScoreSnapshot.create_or_find_by!(user: user, trust_algorithm_version: version, fingerprint: fingerprint) do |record|
          record.assign_attributes(result: result, contributions: contributions, calculated_at: Time.current)
        end
        if version.status == "active"
          profile = TrustProfile.find_or_initialize_by(user: user)
          profile.update!(trust_score_snapshot: snapshot)
        end
      end
    end
  end
end
