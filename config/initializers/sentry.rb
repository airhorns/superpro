# frozen_string_literal: true

Raven.configure do |config|
  if Rails.env.production?
    config.dsn = ENV["BACKEND_SENTRY_DSN"]
    config.release = AppRelease.current
  end

  config.silence_ready = true
  config.logger = SemanticLogger[Raven]
end
