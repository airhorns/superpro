if Rails.env.production?
  Raven.configure do |config|
    config.dsn = "https://d97c1a05b1074872b53a5d1ec6fc3e27:627151eb11a941b3ae3789b9ddf3da26@sentry.io/1435978"
  end
end
