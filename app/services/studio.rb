class Studio
  def self.change!(actor:, settings:, name:, source: nil, reset: nil)
    raise Pundit::NotAuthorizedError unless actor.permission?("content.manage") || actor.super_admin?
    raise Pundit::NotAuthorizedError if !actor.super_admin? && (settings.fetch("tokens", {}).present? || settings["editorial_resets"].present? || reset.present?)
    data = source ? source.settings.except("editorial_resets").deep_dup : {}
    if reset.present?
      path = reset.split(".")
      raise Exchanges::Invalid, "Reset inconnu" unless path.size <= 3 && %w[site tokens pages].include?(path.first)
      if path.first == "site"
        data = {}
      else
        parent = path[0...-1].reduce(data) { |item, key| item.fetch(key, {}) }
        parent.delete(path.last)
      end
    else
      data = data.deep_merge(settings)
    end
    if reset == "site" || reset == "pages" || reset.to_s.match?(/\Apages\.(don|echange|points|fonctionnement)\z/)
      scope = ContentVersion.live.where(kind: "page")
      scope = scope.where(slug: reset.split(".").last) if reset.start_with?("pages.")
      ids = scope.order(:version, :id).to_a.uniq(&:slug).map(&:id)
      data["editorial_resets"] = ids if ids.any?
    end
    StudioVersion.transaction do
      version = StudioVersion.create!(author: actor, settings: data, name: name)
      AuditLog.create!(actor: actor, target: version, action: "studio.draft", reason: reset.present? ? "Retour au défaut #{reset}" : "Nouvelle proposition de présentation")
      version
    end
  end
  def self.transition!(version:, actor:, action:, reason:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("content.manage")
    version.with_lock do
      raise Exchanges::Invalid, "Une version publiée ne se modifie pas : créez un brouillon." if version.status == "published"
      version.validate!
      raise Exchanges::Invalid, "Contraste insuffisant : #{version.contrast_errors.join(', ')}" if version.contrast_errors.any?
      case action
      when "validate" then version.update!(status: "validated", validated_digest: version.digest)
      when "publish"
        raise Exchanges::Invalid, "Validez la prévisualisation avant publication." unless version.status == "validated" && version.validated_digest == version.digest
        version.settings.fetch("editorial_resets", []).each do |id|
          original = ContentVersion.find(id)
          attributes = original.attributes.slice("kind", "slug", "title", "summary", "body", "decorations")
          number = ContentVersion.where(kind: original.kind, slug: original.slug).maximum(:version) + 1
          ContentVersion.create!(**attributes.symbolize_keys, author: actor, version: number, published_at: Time.current)
        end
        version.update!(status: "published", published_at: Time.current)
      else raise Exchanges::Invalid, "Action inconnue."
      end
      AuditLog.create!(actor: actor, target: version, action: "studio.#{action}", reason: reason)
    end
  end
end
