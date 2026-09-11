class MissionApplication < ApplicationRecord
  belongs_to :volunteer_mission
  belongs_to :user
  has_many :mission_messages, dependent: :restrict_with_exception
  encrypts :message
  validates :message, presence: true, length: { maximum: 3000 }
  validates :status, inclusion: { in: %w[pending accepted rejected withdrawn] }
  validates :starts_on, :ends_on, presence: true
  def manageable_by?(actor) = OrganizationPolicy.new(actor, volunteer_mission.organization).manage_team?
  def visible_to?(actor) = actor && (user_id == actor.id || manageable_by?(actor))
end
