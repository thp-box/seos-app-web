class Message < ApplicationRecord
  belongs_to :service_request
  belongs_to :sender, class_name: "User"
  has_one_attached :attachment
  encrypts :body
  validates :body, presence: true, length: { maximum: 5000 }
  validates :delivery_key, presence: true, length: { maximum: 80 }
  validate do
    errors.add(:sender, "doit participer à l’échange") unless service_request&.participant?(sender)
  end
end
