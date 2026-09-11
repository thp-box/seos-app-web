class CookieConsent < ApplicationRecord
  VERSION = "cookies-2026-09-v1"
  validates :version, inclusion: { in: [ VERSION ] }
  validates :visitor_digest, :expires_at, presence: true
end
