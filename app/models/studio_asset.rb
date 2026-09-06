class StudioAsset < ApplicationRecord
  belongs_to :author, class_name: "User"
  has_one_attached :image
  def publicly_visible?
    StudioVersion.current&.settings&.fetch("pages", {})&.values&.any? { |fields| fields["image"] == "asset:#{id}" }
  end
end
