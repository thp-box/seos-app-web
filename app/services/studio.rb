class Studio
  def self.change!(actor:, settings:, name:, source: nil, reset: nil)
    raise Pundit::NotAuthorizedError unless actor.permission?("content.manage") || actor.super_admin?
    raise Pundit::NotAuthorizedError if !actor.super_admin? && (settings.fetch("tokens", {}).present? || (settings["editorial_resets"].present? || settings.key?("site")) || reset.present?)
    data = source ? source.settings.except("editorial_resets").deep_dup : {}
    if reset.present?
      path = reset.split(".")
      raise Exchanges::Invalid, "Reset inconnu" unless path.size <= 3 && %w[site tokens pages].include?(path.first)
      if path.first == "site"
        data = {}
      else
        parent = path[0...-1].reduce(data) { |item, key| item.fetch(key, {}) }
        parent.delete(path.last)
        if path.first == "pages" && path.size <= 2
          path.size == 1 ? data.fetch("site", {}).delete("pages") : data.dig("site", "pages")&.delete(path.last)
        end
      end
    else
      data = data.deep_merge(settings)
      data["site"] = settings["site"].deep_dup if settings.key?("site")
      data["tokens"] = settings["tokens"].deep_dup if settings.key?("site") && settings.key?("tokens")
    end
    if reset == "site" || reset == "pages" || reset.to_s.match?(/\Apages\.(don|echange|points|fonctionnement)\z/)
      scope = ContentVersion.live.where(kind: "page")
      scope = scope.where(slug: reset.split(".").last) if reset.start_with?("pages.")
      ids = scope.order(:version, :id).to_a.uniq(&:slug).map(&:id)
      data["editorial_resets"] = ids if ids.any?
    end
    StudioVersion.transaction do
      version = StudioVersion.create!(author: actor, settings: data, name: name)
      AuditLog.create!(actor: actor, target: version, action: "studio.draft", reason: reset.present? ? "Retour au défaut #{reset}" : "Nouvelle proposition de présentation", metadata: source ? { "from" => source.id, "to" => version.id } : {})
      version
    end
  end
  def self.review_errors(version)
    version.site.fetch("pages", {}).filter_map do |_slug, page|
      visible = page["blocks"].reject { |block| block["hidden"] }
      "Ajoutez du contenu à la page « #{page['title']} » avant de la mettre en ligne." if visible.empty? || visible.all? { |block| block["template"] == "text" && block["values"].fetch("body", "").blank? }
    end
  end
  def self.publish_from_review!(version:, actor:, digest:, live_id:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("content.manage")
    StudioVersion.transaction do
      version.lock!
      raise Exchanges::Invalid, "Le site ou vos modifications ont changé. Ouvrez à nouveau l’aperçu avant de mettre en ligne." unless version.digest == digest && current_id_matches?(live_id)
      raise Exchanges::Invalid, "Certaines couleurs rendent les textes difficiles à lire. Revenez dans le kit UI/UX et choisissez des couleurs plus contrastées." if version.contrast_errors.any?
      raise Exchanges::Invalid, review_errors(version).join(" ") if review_errors(version).any?
      transition!(version: version, actor: actor, action: "validate", reason: "Vérification automatique avant mise en ligne depuis le Studio admin")
      transition!(version: version, actor: actor, action: "publish", reason: "Mise en ligne confirmée depuis l’aperçu du Studio admin")
    end
  end
  def self.current_id_matches?(id) = StudioVersion.current&.id.to_s == id.to_s
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
