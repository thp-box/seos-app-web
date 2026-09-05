class NotificationEmailJob < ApplicationJob
  retry_on IOError, Timeout::Error, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError
  def perform(notification)
    notification.with_lock do
      return if notification.emailed_at || !notification.user.email_notifications? || !notification.user.active_for_authentication?
      NotificationMailer.notice(notification).deliver_now
      notification.update!(emailed_at: Time.current)
    end
  end
end
