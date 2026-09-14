class RetentionPolicyVersion < ApplicationRecord
  PURPOSES = %w[exports sessions notifications contacts invitations cookie_preferences].freeze
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  validates :name, presence: true
  validates :status, inclusion: { in: %w[draft simulated published] }
  validate do
    unless rules.is_a?(Hash) && rules.keys.sort == PURPOSES.sort && rules.values.all? { |value| value.is_a?(Integer) && value.between?(1, 3650) }
      errors.add(:rules, "doit donner une durée bornée en jours pour chaque finalité, jamais forever")
    end
    errors.add(:rules, "les exports temporaires ont une durée maximale fixe de 1 jour") if rules.is_a?(Hash) && rules["exports"] != 1
    errors.add(:expires_at, "doit suivre la prise d’effet, dans deux ans au maximum") unless effective_at && expires_at && expires_at > effective_at && expires_at <= effective_at + 2.years
  end
  def fingerprint = Digest::SHA256.hexdigest([ rules, effective_at, expires_at ].to_json)
  def readonly? = persisted? && status_in_database == "published"
  def self.current = where(status: "published").where("effective_at <= ? AND expires_at > ?", Time.current, Time.current).order(effective_at: :desc, id: :desc).first
end
