class Infrastructure::PeriodicSyncAllGlobalConnectionsJob < Que::Job
  def run
    Infrastructure::SingerGlobalSync.run_in_background("snowplow_kafka")
  end

  def log_level(_elapsed)
    :info
  end
end
