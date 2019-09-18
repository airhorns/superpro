# frozen_string_literal: true

ENV["HONEYCOMB_DISABLE_AUTOCONFIGURE"] = "true"
require "honeycomb-beeline"
require "honeycomb/integrations/active_support"
require "honeycomb/integrations/rack"
require "honeycomb/integrations/faraday"

Honeycomb.configure do |config|
  config.write_key = "54cee8187c9b4ef53c14aedef14948b8"
  config.dataset = "core-production-rails"
  config.notification_events = %w[
    sql.active_record
    render_template.action_view
    render_partial.action_view
    render_collection.action_view
    process_action.action_controller
    send_file.action_controller
    send_data.action_controller
    deliver.action_mailer
  ].freeze

  config.sample_hook do |_fields|
    if Rails.env.production?
      [true, 1]
    else
      [false, 0]
    end
  end
end

Rails.configuration.middleware.insert_before(
  RailsSemanticLogger::Rack::Logger,
  Honeycomb::Rack::Middleware,
  client: Honeycomb.client,
)
