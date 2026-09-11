class ProviderErasureTask < ApplicationRecord
  belongs_to :data_request
  encrypts :response
  validates :provider, inclusion: { in: %w[google stripe backups] }
  validates :status, inclusion: { in: %w[pending completed] }
end
