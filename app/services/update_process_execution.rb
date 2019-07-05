class UpdateProcessExecution
  def initialize(account, user)
    @account = account
    @user = user
  end

  def update(process_execution, attributes)
    success = ProcessExecution.transaction do
      process_execution.assign_attributes(attributes)

      parsed = process_execution.document.is_a?(Hash) ? process_execution.document : JSON.parse(process_execution.document)
      doc = Slate::Doc.new(parsed)
      track_todo_stats(doc, process_execution)
      track_related_users(doc, process_execution)
      self.class.track_closest_future_deadline(doc, process_execution)

      process_execution.save
    end

    if success
      return process_execution, nil
    else
      return nil, process_execution.errors
    end
  end

  def self.track_closest_future_deadline(doc, process_execution)
    now = Time.now.utc
    closest_future_deadline = nil

    doc.visit do |node|
      if node["type"] == "deadline" && node["data"] && node["data"]["dueDate"]
        due_date = node["data"]["dueDate"].to_datetime.utc
        if due_date > now
          closest_future_deadline = [closest_future_deadline, due_date].compact.min
        end
      end
    end

    process_execution.closest_future_deadline = closest_future_deadline
  end

  private

  def track_todo_stats(doc, process_execution)
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
    end

    process_execution.open_todo_count = open_todo_count
    process_execution.closed_todo_count = closed_todo_count
    process_execution.total_todo_count = total_todo_count
  end

  def track_related_users(doc, process_execution)
    existing = process_execution.process_execution_involved_users.index_by { |record| record.user_id.to_s }
    user_ids = []

    doc.visit do |node|
      if node["type"] == "check-list-item" && node["data"] && node["data"]["ownerId"]
        user_ids.push(node["data"]["ownerId"].to_s)
      end
    end

    user_ids.uniq!
    new_join_records = user_ids.map { |string_id| existing[string_id] || process_execution.process_execution_involved_users.build(user_id: string_id, account_id: @account.id) }
    process_execution.process_execution_involved_users = new_join_records
  end
end
