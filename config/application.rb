require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SeosFrance
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [ :fr ]
    config.time_zone = "Paris"
    config.action_mailer.logger = nil
    config.active_record.schema_format = :sql
    # Les uploads ouvriront leurs routes authentifiées avec F-006/F-009.
    config.active_storage.draw_routes = false
    config.generators do |generator|
      generator.test_framework :rspec, fixture: false, view_specs: false, helper_specs: false, routing_specs: false
      generator.fixture_replacement :factory_bot, dir: "spec/factories"
      generator.system_tests = nil
    end

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
