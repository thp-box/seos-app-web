module AdminNavigationHelper
  def admin_navigation_groups
    groups = []
    if current_user.super_admin?
      groups << { label: "Personnalisation", links: [
        admin_nav_item("Pages et sections", personalization_path("pages"), personalization_active?("pages")),
        admin_nav_item("Kit UI/UX", personalization_path("kit"), personalization_active?("kit"))
      ] }
    end
    definitions = [
      [ "Communauté", [
        [ "Membres", admin_users_path, %w[users.read], "admin/users" ],
        workbench_navigation("Profils publics", "profils"),
        [ "Organisations et voyage", admin_network_index_path, %w[organizations.read organizations.manage organizations.legal missions.manage partnerships.manage], "admin/network" ],
        [ "Engagement et chaînes", admin_community_index_path, %w[community.read community.manage community.rules], "admin/community" ]
      ] ],
      [ "Annonces et échanges", [
        workbench_navigation("Annonces", "annonces"), workbench_navigation("Échanges", "echanges"),
        workbench_navigation("Signalements", "signalements"), workbench_navigation("Demandes de contact", "contacts")
      ] ],
      [ "Confiance et finances", [
        [ "Confiance et recours", admin_trust_index_path, %w[trust.read trust.manage], "admin/trust", "index" ],
        [ "Signaux à examiner", risks_admin_trust_index_path, %w[trust.risk], "admin/trust", "risks" ],
        [ "Points Services", admin_points_path, %w[points.read points.adjust points.rewards points.rules], "admin/points" ],
        [ "Soutien financier", admin_financial_support_index_path, %w[financial.read financial.manage], "admin/financial_support" ]
      ] ],
      [ "Gestion du site", [
        workbench_navigation("Journal et textes légaux", "contenus"),
        workbench_navigation("Catégories d’annonces", "categories"), workbench_navigation("Restrictions de catégories", "restrictions")
      ] ],
      [ "Administration", [
        [ "Pilotage et registres", admin_operations_path, OperationsCatalogue::RESOURCES.values.map { |entry| entry[1] }.uniq, "admin/operations" ],
        [ "Confidentialité", admin_privacy_index_path, %w[privacy.manage privacy.rules], "admin/privacy" ],
        [ "Journal d’audit", admin_audit_logs_path, %w[audit.read], "admin/audit_logs" ]
      ] ]
    ]
    definitions.each do |label, entries|
      links = entries.filter_map do |text, path, permissions, controller, action, kind|
        next unless permissions.any? { |permission| current_user.permission?(permission) }
        active = controller_path == controller && (!action || action_name == action) && (!kind || params[:kind] == kind)
        admin_nav_item(text, path, active)
      end
      groups << { label: label, links: links } if links.any?
    end
    if current_user.super_admin?
      groups.last[:links] += [
        admin_nav_item("Carte publique", edit_super_admin_map_setting_path, controller_path == "super_admin/map_settings"),
        admin_nav_item("Administrateurs", super_admin_administrators_path, controller_path == "super_admin/administrators")
      ]
    elsif current_user.permission?("content.manage") || current_user.permission?("studio.preview")
      group = groups.find { |item| item[:label] == "Gestion du site" }
      group ||= { label: "Gestion du site", links: [] }.tap { |item| groups << item }
      group[:links] << admin_nav_item("Propositions éditoriales", admin_studio_index_path, controller_path == "admin/studio")
    end
    groups
  end

  def admin_nav_item(label, path, active) = { label: label, path: path, active: active }

  def workbench_navigation(label, kind)
    [ label, admin_workbench_index_path(kind: kind), [ Admin::WorkbenchController::RESOURCES.fetch(kind)[1] ], "admin/workbench", nil, kind ]
  end

  def personalization_path(area)
    if controller_path == "admin/site" && @version&.persisted?
      edit_admin_site_path(@version, area: area, page: params[:page])
    else
      admin_site_index_path(area: area)
    end
  end

  def personalization_active?(area)
    return area == "pages" if controller_path == "admin/studio"
    controller_path == "admin/site" && (area == "kit" ? params[:area] == "kit" || action_name == "kit" : params[:area] != "kit" && action_name != "kit")
  end
end
