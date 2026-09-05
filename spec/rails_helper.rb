require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("Tests interdits en production") if Rails.env.production?
require "rspec/rails"
require "webmock/rspec"
require "capybara/rspec"
require "axe-rspec"
WebMock.disable_net_connect!(allow_localhost: true)
ActiveRecord::Migration.maintain_test_schema!
Rails.application.eager_load!
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }
RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers
  config.before do
    Rack::Attack.cache.store.clear
    ActionMailer::Base.deliveries.clear
  end
end
