require "bundler/setup"
require 'awesome_print'
require 'webmock/rspec'
require "apisync/rails"

WebMock.disable_net_connect!

# Loads test app
require File.expand_path("../../spec/test_app/config/environment.rb", __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../spec/test_app/db/migrate", __FILE__)]

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Apisync.api_key = "random-key"
  end

  config.before(:each, :integration) do |ex|
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :integration) do |example|
    DatabaseCleaner.start
  end

  config.append_after(:each, :integration) do
    DatabaseCleaner.clean
  end
end
