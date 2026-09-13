# Resolve boundaries from the visible composition, not the original template order.
class SiteSectionSurface
  COLORS = { "cream" => "var(--cream)", "mist" => "var(--mist)", "seos" => "color-mix(in srgb,var(--seos) 65%,var(--deep))", "deep" => "var(--deep)" }.freeze
  DEFAULTS = { "home-0" => "deep", "home-2" => "seos", "home-4" => "deep", "home-6" => "seos", "home-8" => "deep", "home-10" => "seos", "don-0" => "deep", "exchange-0" => "deep", "points-0" => "deep", "travel-hero" => "deep", "community-support" => "seos" }.freeze
  SHAPES = %w[wave_double soft_curve wave_double asymmetric_blob wave_double soft_curve asymmetric_blob wave_double soft_curve wave_double wave_double].freeze
  def self.shape(block)
    index = block["template"][/\Ahome-(\d+)\z/, 1]
    index ? SHAPES.fetch(index.to_i, "wave_double") : "wave_double"
  end
  def self.motion(block)
    selected = block.dig("style", "wave_motion")
    return selected == "gentle" if selected && selected != "normal"
    %w[home-2 home-4 home-8 home-10].include?(block["template"])
  end
  def self.tone(block)
    selected = block&.dig("style", "tone")
    COLORS.key?(selected) ? selected : DEFAULTS.fetch(block&.fetch("template", nil), "cream")
  end
  def self.css(blocks)
    blocks.each_with_index.map do |block, index|
      previous = index.positive? ? tone(blocks[index - 1]) : "cream"
      following = blocks[index + 1]
      next_tone = following && following["placement"] == "top" && ContentVersion::PRESETS.include?(following["separator"]) ? tone(block) : tone(following)
      "#site-section-#{block.fetch('id')}{--section-bg:#{COLORS.fetch(tone(block))};--previous-bg:#{COLORS.fetch(previous)};--next-bg:#{COLORS.fetch(next_tone)}}"
    end.join
  end
  def self.automatic?(block)
    html = SiteDesign.templates.fetch(block["template"])["html"].to_s
    html.include?("yoga-separator") && !html.include?("hero-organic-cut")
  end
end
