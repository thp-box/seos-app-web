class PrivacyMaintenanceJob < ApplicationJob
  def perform
    DataRequest.where("export_expires_at <= ?", Time.current).joins(:export_file_attachment).find_each { |request| request.export_file.purge }
  end
end
