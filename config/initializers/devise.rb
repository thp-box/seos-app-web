Devise.setup do |config|
  config.mailer_sender = ENV.fetch("SEOS_MAIL_FROM", "SEOS <noreply@example.test>")
  require "devise/orm/active_record"
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 12..128
  config.reconfirmable = true
  config.allow_unconfirmed_access_for = 0.days
  config.confirm_within = 3.days
  config.reset_password_within = 2.hours
  config.sign_in_after_reset_password = false
  config.sign_in_after_change_password = false
  config.timeout_in = 30.minutes
  config.lock_strategy = :failed_attempts
  config.unlock_strategy = :time
  config.maximum_attempts = 10
  config.unlock_in = 30.minutes
  config.paranoid = true
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other
end
