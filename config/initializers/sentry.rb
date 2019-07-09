if Rails.env.production?
  Raven.configure do |config|
    config.dsn = ENV["BACKEND_SENTRY_DSN"]
    config.release = AppRelease.current
    config.silence_ready = true
  end
end
