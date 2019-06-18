if Rails.env.production?
  Raven.configure do |config|
    config.dsn = ENV["BACKEND_SENTRY_DSN"]
  end
end
