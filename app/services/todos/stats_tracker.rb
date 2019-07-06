module Todos::StatsTracker
  class << self
    def track_all(document_owner)
      doc = Slate::Doc.parse(document_owner.document)
      self.track_todo_stats(doc, document_owner)
      self.track_closest_future_deadline(doc, document_owner)
      self.track_related_users(doc, document_owner) if document_owner.respond_to?(:process_execution_involved_users)
      document_owner
    end

    def track_closest_future_deadline(doc, document_owner)
      now = Time.now.utc
      closest_future_deadline = nil

      doc.visit do |node|
        if node["type"] == "deadline" && node["data"] && node["data"]["dueDate"]
          due_date = node["data"]["dueDate"].to_datetime.utc
          if due_date > now
            closest_future_deadline = [closest_future_deadline, due_date].compact.min
          end
        end
        true
      end

      document_owner.closest_future_deadline = closest_future_deadline
    end

    def track_todo_stats(doc, document_owner)
      open_todo_count = 0
      closed_todo_count = 0
      total_todo_count = 0

      doc.visit do |node|
        if node["type"] == "check-list-item" && node["data"]
          total_todo_count += 1
          if node["data"]["checked"]
            open_todo_count += 1
          else
            closed_todo_count += 1
          end
        end
        true
      end

      document_owner.open_todo_count = open_todo_count
      document_owner.closed_todo_count = closed_todo_count
      document_owner.total_todo_count = total_todo_count
    end

    def track_related_users(doc, document_owner)
      existing = document_owner.process_execution_involved_users.index_by { |record| record.user_id.to_s }
      user_ids = []

      doc.visit do |node|
        if node["type"] == "check-list-item" && node["data"] && node["data"]["ownerId"]
          user_ids.push(node["data"]["ownerId"].to_s)
        end
        true
      end

      user_ids.uniq!
      new_join_records = user_ids.map { |string_id| existing[string_id] || document_owner.process_execution_involved_users.build(user_id: string_id, account_id: document_owner.account_id) }
      document_owner.process_execution_involved_users = new_join_records
    end
  end
end
