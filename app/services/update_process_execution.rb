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
      track_related_users(doc, process_execution)
      process_execution.save
    end

    if success
      return process_execution, nil
    else
      return nil, process_execution.errors
    end
  end

  private

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
