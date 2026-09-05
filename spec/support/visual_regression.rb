require "chunky_png"
module VisualRegression
  WIDTHS = [ 320, 375, 414, 768, 1024, 1280, 1440 ].freeze

  def compare_visual(name)
    page.execute_script("document.activeElement.blur()")
    page.evaluate_async_script("const done = arguments[0]; document.fonts.ready.then(() => requestAnimationFrame(() => requestAnimationFrame(done)))")
    actual_path = Rails.root.join("tmp/screenshots", "#{name}.png")
    FileUtils.mkdir_p(actual_path.dirname)
    metrics = page.driver.browser.execute_cdp("Page.getLayoutMetrics")["cssContentSize"]
    capture = page.driver.browser.execute_cdp("Page.captureScreenshot", format: "png", captureBeyondViewport: true,
      clip: { x: 0, y: 0, width: page.evaluate_script("window.innerWidth"), height: metrics["height"], scale: 1 })
    File.binwrite(actual_path, Base64.decode64(capture.fetch("data")))
    if ENV["CAPTURE_VISUAL_CANDIDATES"] == "1"
      raise "La CI doit comparer les baselines" if ENV["CI"].present?
      return
    end

    baseline_path = Rails.root.join("spec/fixtures/visual/foundations", "#{name}.png")
    expect(baseline_path).to exist, "Baseline absente : #{baseline_path}. Capturer et examiner une référence explicitement."
    expected = ChunkyPNG::Image.from_file(baseline_path)
    actual = ChunkyPNG::Image.from_file(actual_path)
    expect([ actual.width, actual.height ]).to eq([ expected.width, expected.height ])
    changed = expected.pixels.zip(actual.pixels).count { |left, right| left != right }
    ratio = changed.to_f / expected.pixels.size
    if ratio > 0.005
      diff = ChunkyPNG::Image.new(actual.width, actual.height, ChunkyPNG::Color::TRANSPARENT)
      expected.pixels.zip(actual.pixels).each_with_index do |(left, right), index|
        diff[index % actual.width, index / actual.width] = ChunkyPNG::Color::RED if left != right
      end
      diff.save(Rails.root.join("tmp/screenshots", "#{name}-diff.png"))
    end
    expect(ratio).to be <= 0.005, "Écart visuel #{(ratio * 100).round(2)} % pour #{name} (maximum 0,5 %)."
  end
end
RSpec.configure { |config| config.include VisualRegression, type: :system }
