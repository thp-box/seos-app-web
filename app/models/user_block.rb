class UserBlock < ApplicationRecord
  belongs_to :user
  belongs_to :blocked_user, class_name: "User"
  validates :blocked_user_id, uniqueness: { scope: :user_id }
  def self.between?(first, second)
    where(user_id: first, blocked_user_id: second).or(where(user_id: second, blocked_user_id: first)).exists?
  end
end
