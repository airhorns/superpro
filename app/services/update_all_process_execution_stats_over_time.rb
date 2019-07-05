# ProcessExecutions track their closest future deadline which, because time marches on, can change as the closest deadline is reached
# and passed. This periodically checks if their deadlines have arrived and updates them if so
class UpdateAllProcessExecutionStatsOverTime
  def update_stats
    ProcessExecution.where("closest_future_deadline < ?", Time.now.utc).find_each do |execution|
      doc = Slate::Doc.new(execution.document)
      UpdateProcessExecution.track_closest_future_deadline(doc, execution)
      if execution.changed?
        execution.save!
      end
    end
  end
end
