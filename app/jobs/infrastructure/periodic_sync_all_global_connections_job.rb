# frozen_string_literal: true

class Infrastructure::PeriodicSyncAllGlobalConnectionsJob < Que::Job
  def run
    Infrastructure::SingerGlobalSync.run_in_background("snowplow_kafka")
    # Infrastructure::SingerGlobalSync.run_in_background("snowplow_kafka_errors")
  end

  def log_level(_elapsed)
    :info
  end
end
