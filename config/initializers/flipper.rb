Flipper.configure do |config|
  config.default do
    database_adapter = Flipper::Adapters::ActiveRecord.new
    cache = ActiveSupport::Cache::MemoryStore.new
    adapter = Flipper::Adapters::ActiveSupportCacheStore.new(database_adapter, cache, expires_in: 5.minutes)
    flipper = Flipper.new(adapter)
  end
end
