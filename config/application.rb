# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../app/lib/silent_log_middleware"

module Superpro
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.autoload_paths << Rails.root.join("app", "services")
    config.autoload_paths << Rails.root.join("app", "graphql")
    config.autoload_paths << Rails.root.join("app", "warehouse")
    config.autoload_paths << Rails.root.join("app", "lib")
    config.autoload_paths << Rails.root.join("test", "lib")

    config.generators do |g|
      g.factory_bot suffix: "factory"
    end

    config.active_record.index_nested_attribute_errors = true

    # Needed for views and postgres extensions
    config.active_record.schema_format = :sql

    config.x.domains.app = "should set in the environments"
    config.x.domains.admin = "should be set in the environments"

    config.admin = config_for(:admin)
    config.plaid = config_for(:plaid)
    config.shopify = config_for(:shopify)
    config.singer_importer = config_for(:singer_importer)
    config.google = config_for(:google)
    config.facebook = config_for(:facebook)
    config.kubernetes = config_for(:kubernetes)
    config.kafka = config_for(:kafka)

    config.rails_semantic_logger.semantic = true

    config.log_tags = {
      request_id: :request_id,
      user_id: ->(request) { request.session[:current_user_id] },
      account_id: ->(request) { request.session[:current_account_id] },
      client_session_id: ->(request) { request.headers["X-Client-Session-Id"] },
    }

    # Make sure that the semantic logger middleware which evaluats the above log_tags procs has a session on the request
    config.middleware.move_after ActionDispatch::Session::CacheStore, RailsSemanticLogger::Rack::Logger, config.log_tags
    config.middleware.insert_before ActionDispatch::Static, SilentLogMiddleware, silence: ["/health_check", %r{^/assets/}, "/favicon.ico"]
    config.middleware.use Flipper::Middleware::Memoizer
  end
end
