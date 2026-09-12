module AccountDashboardHelper
  def account_page_heading(title, eyebrow: "Mon espace SEOS", &block)
    content_tag(:header, class: "account-page-heading") do
      safe_join([ content_tag(:div, safe_join([ content_tag(:p, eyebrow, class: "account-eyebrow"), content_tag(:h1, title) ])), (capture(&block) if block) ].compact)
    end
  end

  def account_quest_reward(quest, rule)
    return unless rule
    return "Selon les services validés" if quest.event_name == "chain"
    amount = quest.event_name == "referral" ? 15 : rule.configuration[quest.reward_key]
    amount = amount[Points::Rewards.level(current_user, rule)] if amount.is_a?(Hash)
    "Jusqu’à +#{amount} PS" if amount
  end

  def account_quest_cover(quest)
    photos = {
      "listing" => "photo-1497366811353-6870744d04b257964d7a.jpg",
      "written" => "photo-1455390582262-044cdead277a93c85362.jpg",
      "share" => "photo-1611162617474-5b21e879e1131f73e650.jpg",
      "responses" => "photo-1521737604893-d14cc237f11d6a93a504.jpg"
    }
    "maquette/#{photos.fetch(quest.reward_key, 'photo-1529156069898-49953e39b3acd068637d.jpg')}"
  end

  def account_level_name(level)
    { "bronze" => "Bronze", "silver" => "Argent", "gold" => "Or" }.fetch(level)
  end
end
