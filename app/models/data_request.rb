class DataRequest < ApplicationRecord
  KINDS = %w[access portability rectification erasure restriction objection withdrawal].freeze
  after_update_commit :notify_status, if: -> { saved_change_to_status? && %w[reviewed completed partial rejected].include?(status) }
  def notify_status
    Notification.notify!(user: user, key: "privacy:#{id}:#{updated_at.to_f}:#{status}", title: "Votre demande concernant vos données personnelles a été mise à jour.", category: "privacy")
  end
  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  has_one_attached :export_file
  has_many :provider_erasure_tasks, dependent: :restrict_with_exception
  encrypts :details, :response
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: %w[pending reviewed executing completed partial rejected] }
  validates :details, length: { maximum: 3000 }
  validates :response_due_at, presence: true
  def export_available? = export_file.attached? && export_expires_at && export_expires_at > Time.current
end
