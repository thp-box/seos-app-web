require "rails_helper"
RSpec.describe "Références visuelles du socle", :"F-002", :"F-007", :visual, type: :system do
  VisualRegression::WIDTHS.each do |width|
    it "affiche accueil et connexion sans débordement à #{width}px" do
      resize_viewport(width)
      { home: root_path, login: new_user_session_path }.each do |name, path|
        visit path
        expect(page.evaluate_script("window.innerWidth")).to eq(width)
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
        compare_visual("#{name}-#{width}")
      end
    end
  end

  it "reste utilisable à 200 % de zoom" do
    resize_viewport(1280)
    visit new_user_session_path
    page.execute_script("document.documentElement.style.zoom = '2'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= document.documentElement.clientWidth")).to be(true)
    expect(page).to have_field("E-mail")
    expect(page).to have_button("Se connecter")
  end
end
