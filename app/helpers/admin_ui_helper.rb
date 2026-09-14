module AdminUiHelper
  def network_record_title(record)
    case record
    when Organization then record.name
    when Partnership then record.public_title
    else record.title
    end
  end

  def admin_ui_icon(name)
    paths = {
      "network" => [ "M8 5h8M6 9v6m12-6v6M8 19h8", "M6 2a3 3 0 1 0 0 6 3 3 0 0 0 0-6Zm12 0a3 3 0 1 0 0 6 3 3 0 0 0 0-6ZM6 16a3 3 0 1 0 0 6 3 3 0 0 0 0-6Zm12 0a3 3 0 1 0 0 6 3 3 0 0 0 0-6Z" ],
      "shield" => [ "M12 3 3 7v5c0 5 9 9 9 9s9-4 9-9V7l-9-4Z", "m8 12 3 3 5-6" ],
      "grid" => [ "M3 3h7v7H3V3Zm11 0h7v7h-7V3ZM3 14h7v7H3v-7Zm11 0h7v7h-7v-7Z" ],
      "arrow" => [ "M5 12h14m-6-6 6 6-6 6" ]
    }.fetch(name, [ "M4 6h16M4 12h16M4 18h16" ])
    tag.svg(viewBox: "0 0 24 24", width: 24, height: 24, fill: "none", stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true) do
      safe_join(paths.map { |path| tag.path(d: path) })
    end
  end

  def admin_current_section
    admin_navigation_groups.flat_map { |group| group[:links] }.find { |link| link[:active] }&.fetch(:label) || "Vue d’ensemble"
  end
end
