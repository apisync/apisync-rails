require "bundler/setup"

require "active_support"
require "apisync"
require "apisync/rails/version"
require "apisync/rails/model"
require "apisync/rails/http"
require "apisync/active_record_extension"
require "apisync/rails/sync_model_job/sidekiq"
require "apisync/rails/extensions"

class Apisync
  module Rails
  end
end

# This class, Extensions, is responsible for including extensions into
# our own classes (and ActiveRecord::Base). For example, if Sidekiq is defined
# then we include it into our worker classes. That way we don't need to load
# the Sidekiq gem and force it into client codebases.
Apisync::Rails::Extensions.setup
