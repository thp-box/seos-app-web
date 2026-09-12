module ProfileMenuHelper
  def profile_menu_icon(name)
    paths = {
      "home" => "M3 10 12 3 21 10V21H15V14H9V21H3Z",
      "chat" => "M21 11A9 9 0 1 1 5 5A9 9 0 0 1 21 11ZM5 19 2 22 3 15",
      "check" => "M5 12 10 17 20 5", "wallet" => "M3 5H20V21H3ZM3 5V3H17M15 11H22V17H15ZM18 14H19",
      "heart" => "M12 21 3 12C-2 5 7 0 12 7C17 0 26 5 21 12Z",
      "settings" => "M9 3H15L16 6 19 7 22 10 20 13 20 17 16 19 14 22 10 22 8 19 4 17 4 13 2 10 5 7 8 6ZM16 12A4 4 0 1 1 8 12A4 4 0 1 1 16 12",
      "bell" => "M5 16V9A7 7 0 0 1 19 9V16L22 19H2ZM9 22H15",
      "logout" => "M10 3H3V21H10M8 12H22M17 7 22 12 17 17"
    }
    tag.svg(viewBox: "-2 -2 28 28", fill: "none", stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round", aria: { hidden: true }) { tag.path(d: paths.fetch(name)) }
  end
end
