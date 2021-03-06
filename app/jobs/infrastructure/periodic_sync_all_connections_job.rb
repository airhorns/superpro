# frozen_string_literal: true

class Infrastructure::PeriodicSyncAllConnectionsJob < Que::Job
  def run
    Connection.kept.where(strategy: "singer", enabled: true).find_each do |connection|
      Infrastructure::SingerConnectionSync.run_in_background(connection)
    end
  end

  def log_level(_elapsed)
    :info
  end
end
