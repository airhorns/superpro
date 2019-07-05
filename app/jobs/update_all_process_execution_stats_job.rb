class UpdateAllProcessExecutionStatsJob < Que::Job
  def run
    UpdateAllProcessExecutionStatsOverTime.new.update_stats
  end
end
