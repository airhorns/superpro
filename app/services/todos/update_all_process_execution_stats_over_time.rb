# ProcessExecutions track their closest future deadline which, because time marches on, can change as the closest deadline is reached
# and passed. This periodically checks if their deadlines have arrived and updates them if so
class Todos::UpdateAllProcessExecutionStatsOverTime
  def update_stats
    [ProcessExecution, Scratchpad].each do |klass|
      klass.where("closest_future_deadline < ?", Time.now.utc).find_each do |document_owner|
        doc = Slate::Doc.new(document_owner.document)
        Todos::StatsTracker.track_closest_future_deadline(doc, document_owner)

        if document_owner.changed?
          document_owner.save!
        end
      end
    end
  end
end
