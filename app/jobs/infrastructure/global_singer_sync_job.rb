class Infrastructure::GlobalSingerSyncJob < Que::Job
  self.maximum_retry_count = 0
  self.exclusive_execution_lock = true

  def run(global_sync_key:)
    Infrastructure::SingerGlobalSync.new(global_sync_key).sync
  end
end
