require "rails_helper"
RSpec.describe "Références visuelles découverte", :visual, type: :system do
  [ 375, 1440 ].each do |width|
    it "affiche le catalogue à #{width}px" do
      travel_to Time.zone.local(2026, 9, 5, 12) do
        profile = create(:profile, display_name: "Camille", public_slug: "camille-demo")
        category = create(:category, name: "Jardinage", slug: "jardinage")
        create(:listing, user: profile.user, category: category, slug: "jardin-demo", title: "Un coup de main au jardin")
        resize_viewport(width)
        visit listings_path
        compare_visual("catalogue-#{width}")
      end
    end
  end
end
