class PartnershipWorkflow
  def self.save!(record:, actor:, attributes:, logo: nil)
    raise Pundit::NotAuthorizedError unless actor.permission?("partnerships.manage") || OrganizationPolicy.new(actor, record.organization).edit_content?
    raise Pundit::NotAuthorizedError if attributes.stringify_keys.key?("kind") && !actor.super_admin?
    record.with_lock do
      record.update!(attributes.merge(status: "draft", approved_at: nil))
      SafeImage.attach!(record.logo, logo) if logo.present?
      AuditLog.create!(actor: actor, target: record, action: "partnership.draft", reason: "Préparation de la présentation du partenariat")
    end
    record
  end

  def self.transition!(record:, actor:, status:, reason:)
    if status == "pending_review"
      raise Pundit::NotAuthorizedError unless OrganizationPolicy.new(actor, record.organization).edit_content? || actor.permission?("partnerships.manage")
    else
      raise Pundit::NotAuthorizedError unless actor.permission?("partnerships.manage")
    end
    raise Exchanges::Invalid, "État inconnu." unless %w[pending_review published archived].include?(status)
    record.with_lock do
      record.valid?(:publication) || raise(ActiveRecord::RecordInvalid, record) if %w[pending_review published].include?(status)
      raise Exchanges::Invalid, "Les partenariats sont désactivés." if status == "published" && !FeatureFlag.partnerships_enabled?
      record.update!(status: status, approved_at: status == "published" ? Time.current : nil, approved_by: status == "published" ? actor : record.approved_by)
      AuditLog.create!(actor: actor, target: record, action: "partnership.#{status}", reason: reason)
    end
  end
end
