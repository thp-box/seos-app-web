module QuestsHelper
  def quest_icon(icon, event = nil)
    icon = { "welcome" => "spark", "listing" => "listing", "responses" => "people", "referral" => "people", "cycle" => "trophy", "written" => "listing", "video" => "heart", "share" => "heart", "chain" => "link" }.fetch(event, "spark") if icon == "spark"
    paths = {
      "spark" => "M12 3 15 9 21 12 15 15 12 21 9 15 3 12 9 9Z",
      "heart" => "M12 21 3 12C-2 5 7 0 12 7C17 0 26 5 21 12Z",
      "trophy" => "M7 3H17V10A5 5 0 0 1 7 10ZM7 5H3V8Q3 12 7 12M17 5H21V8Q21 12 17 12M12 15V21M8 21H16",
      "listing" => "M5 3H19V21H5ZM9 7H15M9 12H15M9 17H12",
      "people" => "M9 3A3 3 0 1 1 9 9A3 3 0 1 1 9 3M2 21V17A7 7 0 0 1 16 17V21M17 4A3 3 0 0 1 17 10M19 14Q23 14 23 21",
      "link" => "M10 14 14 10M8 16 6 18A4 4 0 0 1 0 12L5 7A4 4 0 0 1 11 7M16 8 18 6A4 4 0 0 1 24 12L19 17A4 4 0 0 1 13 17"
    }
    tag.svg(viewBox: "-2 -2 28 28", fill: "none", stroke: "currentColor", "stroke-width": 1.7, "stroke-linecap": "round", "stroke-linejoin": "round", aria: { hidden: true }) { tag.path(d: paths.fetch(icon, paths["spark"])) }
  end

  def quest_recurrence(quest)
    { "once" => "Une fois", "monthly" => "Chaque mois", "cycle" => "Par série" }.fetch(quest.recurrence)
  end

  def quest_action(quest)
    case quest.event_name
    when "listing" then [ "Publier une annonce", new_account_listing_path ]
    when "responses" then [ "Trouver une annonce", listings_path ]
    when "chain" then [ "Poursuivre une chaîne", account_chains_path ]
    when "referral" then [ "Voir mon parrainage", account_trust_path ]
    else [ "Voir comment avancer", account_points_path ]
    end
  end
end
