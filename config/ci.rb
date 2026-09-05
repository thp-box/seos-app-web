CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Assets", "yarn build:check"
  step "Autoload", "bin/rails zeitwerk:check"
  step "Style: Ruby", "bin/rubocop"
  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Yarn vulnerability audit", "yarn audit"
  step "Security: Brakeman", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: RSpec", "bundle exec rspec"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed"
end
