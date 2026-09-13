require "rails_helper"
RSpec.describe "Menu légal pendant le défilement", type: :system do
  it "reste visible devant les documents" do
    admin = create(:user, :super_admin)
    ContentVersion::LEGAL_SLUGS.each do |slug|
      create(:content_version, author: admin, kind: "legal", slug: slug, title: slug, body: ("Un paragraphe de document.\n\n" * 40), published_at: Time.current)
    end
    [ 1440, 375 ].each do |width|
    resize_viewport(width)
    visit legal_center_path
    page.execute_script("window.scrollTo(0, 1300)")
    page.driver.browser.action.pause(duration: 0.3).perform
    expect(page.evaluate_script("document.querySelector('.legal-sidebar').getBoundingClientRect().top")).to be_between(70, 130)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    end
  end
end
