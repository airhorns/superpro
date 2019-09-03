class Infrastructure::PeriodicSyncAllConnectionsJob < Que::Job
  def run
    Connection.where(strategy: "singer", enabled: true).find_each do |connection|
      Infrastructure::SyncSingerConnectionJob.enqueue(connection_id: connection.id)
    end
  end

  def log_level(_elapsed)
    :info
  end
end
