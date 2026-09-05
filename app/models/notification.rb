class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :service_request, optional: true
  after_create_commit -> { NotificationEmailJob.perform_later(self) }
  validates :title, :event_key, presence: true
  def self.notify!(user:, key:, title:, request: nil)
    create_or_find_by!(user: user, event_key: key) do |notice|
      notice.title = title
      notice.service_request = request
    end
  end
end
