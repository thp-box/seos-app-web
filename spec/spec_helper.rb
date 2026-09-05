require "simplecov"
if ENV.fetch("COVERAGE", "1") == "1"
  SimpleCov.start "rails" do
    enable_coverage :branch
    cover "app/**/*.rb"
    minimum_coverage line: 95, branch: 90
    skip "/spec/"
  end
end
RSpec.configure do |config|
  config.expect_with(:rspec) { |expectations| expectations.include_chain_clauses_in_custom_matcher_descriptions = true }
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.order = :random
  Kernel.srand config.seed
  config.example_status_persistence_file_path = "tmp/rspec-examples.txt"
  config.disable_monkey_patching!
end
