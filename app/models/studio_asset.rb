class StudioAsset < ApplicationRecord
  belongs_to :author, class_name: "User"
  has_one_attached :image
  def publicly_visible?
    settings = StudioVersion.current&.settings || {}
    legacy = settings.fetch("pages", {}).values.any? { |fields| fields["image"] == "asset:#{id}" }
    site = settings.fetch("site", {})
    chrome = %w[header footer].any? { |area| site.dig(area, "logo") == "asset:#{id}" }
    blocks = site.fetch("pages", {}).values.flat_map { |page| page.fetch("blocks") }.reject { |block| block["hidden"] }
    legacy || chrome || blocks.any? { |block| block["values"].any? { |key, value| key.start_with?("image-") && value == "asset:#{id}" } }
  end
end
