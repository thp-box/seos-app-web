module ApplicationHelper
  def navigation_link(label, path)
    link_to label, path, aria: { current: ("page" if current_page?(path)) }
  end
end
