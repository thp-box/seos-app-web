require Rails.root.join("lib/seos_mail/gmail")
ActionMailer::Base.add_delivery_method :gmail, SeosMail::Gmail
if ENV["SEOS_MAIL_DELIVERY"] == "gmail"
  Rails.application.config.action_mailer.delivery_method = :gmail
  Rails.application.config.action_mailer.raise_delivery_errors = true
end
