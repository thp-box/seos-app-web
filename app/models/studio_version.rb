class StudioVersion < ApplicationRecord
  DEFAULT_NAME = "SEOS Default v1".freeze
  COLORS = { "deep" => "#004961", "seos" => "#0092C5", "turq" => "#21A2AF", "gold" => "#CDAE4F", "cream" => "#FBFAF4", "mist" => "#EEF7F9", "ink" => "#173947", "muted" => "#64767D", "line" => "#D9E4E6", "white" => "#FFFFFF", "danger" => "#DC674F", "ok" => "#2E956D", "footer" => "#002F40" }.freeze
  OPTIONS = { "radius" => %w[12px 18px 26px 32px], "font-body" => [ "DM Sans, sans-serif", "Playfair Display, serif", "system-ui, sans-serif" ], "font-heading" => [ "Playfair Display, serif", "DM Sans, sans-serif" ], "motion" => %w[none subtle standard], "button-radius" => %w[12px 26px 999px], "card-radius" => %w[16px 24px 38px], "section-space" => %w[48px 72px 92px 112px], "wave-height" => %w[50px 100px 135px 190px], "wave-speed" => %w[4s 8s 12s 20s], "wave-amplitude" => %w[0px 8px 16px 24px], "wave-shape" => %w[wave curve diagonal flat], "shadow" => [ "none", "0 18px 50px rgba(0,73,97,.10)" ] }.freeze
  PAGES = %w[home don echange points fonctionnement].freeze
  belongs_to :author, class_name: "User"
  validates :name, presence: true, length: { maximum: 100 }
  validates :status, inclusion: { in: %w[draft validated published] }
  validate :safe_settings
  def readonly? = persisted? && status_in_database == "published"
  def digest = Digest::SHA256.hexdigest(settings.to_json)
  def self.current = where(status: "published").order(published_at: :desc, id: :desc).first
  def tokens = settings.fetch("tokens", {})
  def page(slug) = settings.fetch("pages", {}).fetch(slug, {})
  def site = settings.fetch("site", {})
  def chrome(area) = SiteDesign::CHROME.fetch(area).merge(site.fetch(area, {}))
  def css
    values = tokens.except("motion").map { |key, value| "--#{key}:#{value};" }.join
    ":root{#{values}}" + StudioTheme.css(tokens) + (tokens["motion"] == "none" ? "*,*::before,*::after{animation:none!important;transition:none!important;scroll-behavior:auto!important}" : "")
  end
  def contrast_errors
    palette = COLORS.merge(tokens.slice(*COLORS.keys))
    [ [ "ink", "cream" ], [ "ink", "mist" ], [ "muted", "white" ], [ "white", "deep" ], [ "white", "footer" ] ].filter_map do |foreground, background|
      values = [ foreground, background ].map { |key| luminance(palette.fetch(key)) }.sort
      "#{foreground}/#{background}" if (values.last + 0.05) / (values.first + 0.05) < 4.5
    end
  end
  private
  def luminance(hex)
    channels = hex.delete_prefix("#").scan(/../).map { |channel| channel.to_i(16) / 255.0 }.map { |c| c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
    channels.zip([ 0.2126, 0.7152, 0.0722 ]).sum { |c, weight| c * weight }
  end
  def safe_settings
    unless settings.is_a?(Hash) && (settings.keys - %w[tokens pages editorial_resets site]).empty? && tokens.is_a?(Hash) && settings.fetch("pages", {}).is_a?(Hash)
      errors.add(:settings, "structure inconnue")
      return
    end
    errors.add(:settings, "document du site invalide") unless SiteDesign.valid?(settings.fetch("site", {}))
    resets = settings.fetch("editorial_resets", [])
    unless resets.is_a?(Array) && resets.size <= PAGES.size && resets.all? { |id| id.is_a?(Integer) && ContentVersion.live.where(kind: "page", id: id).exists? }
      errors.add(:settings, "référence éditoriale invalide")
    end
    tokens.each do |key, value|
      valid = COLORS.key?(key) ? value.is_a?(String) && value.match?(/\A#[0-9a-fA-F]{6}\z/) : OPTIONS.fetch(key, []).include?(value)
      errors.add(:settings, "token interdit : #{key}") unless valid
    end
    settings.fetch("pages", {}).each do |slug, fields|
      unless PAGES.include?(slug) && fields.is_a?(Hash) && (fields.keys - %w[title description image alt separator animated]).empty?
        errors.add(:settings, "page ou champ inconnu")
        next
      end
      fields.each do |key, value|
        valid = case key
        when "image" then value == "seos-logo.png" || (value.is_a?(String) && value.match?(/\Aasset:\d+\z/) && StudioAsset.joins(:image_attachment).exists?(id: value.delete_prefix("asset:")))
        when "separator" then ContentVersion::PRESETS.include?(value)
        when "animated" then [ true, false ].include?(value)
        else value.is_a?(String) && value.size.between?(1, key == "description" ? 3000 : 200) && !value.match?(/[<>]/)
        end
        errors.add(:settings, "contenu interdit : #{slug}/#{key}") unless valid
      end
      errors.add(:settings, "texte alternatif requis") if fields["image"] && fields["alt"].blank?
    end
  end
end
