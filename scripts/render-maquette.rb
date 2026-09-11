require 'selenium-webdriver'
require 'nokogiri'
require 'digest'
Selenium::WebDriver.logger.level = :warn
options = Selenium::WebDriver::Chrome::Options.new
options.binary = ENV.fetch('CHROME_BIN')
%w[--headless=new --no-sandbox --disable-dev-shm-usage --window-size=1440,1000].each { |arg| options.add_argument(arg) }
service = Selenium::WebDriver::Service.chrome(path: ENV.fetch('CHROMEDRIVER_BIN'))
browser = Selenium::WebDriver.for(:chrome, options: options, service: service)
begin
  browser.execute_cdp('Network.enable')
  browser.execute_cdp('Network.setBlockedURLs', urls: [ 'http://*', 'https://*' ])
  browser.navigate.to('file://' + File.expand_path('docs/maquette.html'))
  Selenium::WebDriver::Wait.new(timeout: 10).until { browser.find_elements(css: '.hero-organic-cut').any? }
  document = Nokogiri::HTML(browser.page_source)
  document.css('script').remove
  document.at_css('html')['data-source-sha256'] = Digest::SHA256.file('docs/maquette.html').hexdigest
  File.write('config/studio/rendered-maquette.html', document.to_html)
  puts browser.find_elements(css: '.hero-organic-cut,.page-hero-organic-cut,.section-organic-wave').size
ensure
  browser.quit
end
