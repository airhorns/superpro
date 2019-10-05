# frozen_string_literal: true

Flipper.configure do |config|
  config.default do
    database_adapter = Flipper::Adapters::ActiveRecord.new
    adapter = Flipper::Adapters::ActiveSupportCacheStore.new(database_adapter, Rails.cache, expires_in: 5.minutes)
    Flipper.new(adapter)
  end
end
