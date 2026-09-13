require "rails_helper"
RSpec.describe "Liaisons de chaîne et bulle aquatique", type: :system do
  it "raccorde un seul trait aux cartes mobiles et déforme la bulle sans déplacer son texte" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Mouvements", settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette") }
    [ 1440, 375 ].each do |width|
      resize_viewport(width)
      visit root_path
      page.execute_script("document.querySelector('.chain-example').scrollIntoView({block:'center'})")
      expect(page).to have_css(".chain-connections path", count: 3)
      expect(page.evaluate_script("getComputedStyle(document.querySelector('.chain-example-steps'),'::before').content")).to eq("none")
      page.driver.browser.action.pause(duration: 0.4).perform
      expect(page.evaluate_script(<<~JS)).to be < 2
        (() => {
          const root = document.querySelector('.chain-example-steps'), box = root.getBoundingClientRect();
          const cards = [...root.querySelectorAll('article')].map(e=>e.getBoundingClientRect());
          return Math.max(...[...root.querySelectorAll('path')].flatMap((p,i)=> {
            const a=cards[i], b=cards[i+1], vertical=b.top>=a.bottom-12;
            const start=p.getPointAtLength(0), end=p.getPointAtLength(p.getTotalLength());
            return [Math.abs(start.x+box.x-(vertical?a.x+a.width/2:a.right)),Math.abs(start.y+box.y-(vertical?a.bottom:a.y+a.height/2)),Math.abs(end.x+box.x-(vertical?b.x+b.width/2:b.left)),Math.abs(end.y+box.y-(vertical?b.top:b.y+b.height/2))];
          }));
        })()
      JS
      page.execute_script("document.querySelector('.security-orb').scrollIntoView({block:'center'})")
      expect(page.evaluate_script(<<~JS)).to eq([ true, true, "none" ])
        (() => {
          const orb=document.querySelector('.security-orb'), text=orb.querySelector('[data-field="text-1"]');
          const animation=orb.getAnimations({subtree:true}).find(a=>a.animationName==='studio-water-morph');
          animation.pause(); animation.currentTime=0;
          const before=getComputedStyle(orb,'::before').borderRadius, y=text.getBoundingClientRect().y;
          animation.currentTime=2500;
          return [before!==getComputedStyle(orb,'::before').borderRadius, Math.abs(y-text.getBoundingClientRect().y)<0.1, getComputedStyle(orb).animationName];
        })()
      JS
      page.save_screenshot(Rails.root.join("tmp/screenshots/water-morph-#{width}.png"))
    end
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    expect(page.evaluate_script("getComputedStyle(document.querySelector('.security-orb'),'::before').animationName")).to eq("none")
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end
end
