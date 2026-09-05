class PointAccount < ApplicationRecord
  belongs_to :user, optional: true
  has_many :point_entries, dependent: :restrict_with_exception
  def self.for!(user) = create_or_find_by!(user: user, kind: "user")
  def self.system! = create_or_find_by!(kind: "system", user: nil)
end
