class UpdateAllProcessExecutionStatsJob < Que::Job
  def run
    Todos::UpdateAllProcessExecutionStatsOverTime.new.update_stats
  end
end
