require "selenium/webdriver"
Selenium::WebDriver.logger.level = :warn
Capybara.register_driver :seos_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.browser_version = Rails.root.join(".chrome-version").read.strip
  %w[--headless=new --no-sandbox --disable-dev-shm-usage --window-size=1440,1000 --force-device-scale-factor=1].each { |arg| options.add_argument(arg) }
  options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
  options.add_option("goog:loggingPrefs", { browser: "ALL" })
  service = Selenium::WebDriver::Chrome::Service.new(path: ENV["CHROMEDRIVER_BIN"]) if ENV["CHROMEDRIVER_BIN"].present?
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, **(service ? { service: service } : {}))
end
Capybara.default_max_wait_time = 5
RSpec.configure do |config|
  config.before(:suite) do
    abort "Exécutez yarn build avant les tests." unless system("node", "scripts/check-build.mjs")
  end
  config.include Module.new {
    def resize_viewport(width, height: 1000)
      page.current_window.resize_to(width, height)
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: height, deviceScaleFactor: 1, mobile: false)
    end
  }, type: :system
  config.before(:each, type: :system) do
    driven_by :seos_chrome
    resize_viewport(1440)
  end
end
