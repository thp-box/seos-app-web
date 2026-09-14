require "useragent"

class LoginSession < ApplicationRecord
  belongs_to :user
  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  validates :token_digest, :user_agent_summary, :expires_at, :last_seen_at, presence: true

  def self.issue!(user:, user_agent:)
    token = SecureRandom.hex(32)
    browser = UserAgent.parse(user_agent.to_s)
    record = create!(user: user, token_digest: Digest::SHA256.hexdigest(token),
      user_agent_summary: "#{browser.browser.presence || 'Navigateur'} / #{browser.platform.presence || 'Appareil'}".truncate(120),
      last_seen_at: Time.current, expires_at: 12.hours.from_now, reauthenticated_at: Time.current)
    [ record, token ]
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked_at?
  end

  def recently_authenticated?
    reauthenticated_at.present? && reauthenticated_at > 15.minutes.ago
  end
end
