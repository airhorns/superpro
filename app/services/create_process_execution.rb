class CreateProcessExecution
  def initialize(account, user)
    @account = account
    @user = user
  end

  def create(attributes = nil)
    process_execution = @account.process_executions.build(name: "New Process Execution", creator: @user, owner: @user)

    success = ProcessExecution.transaction do
      process_execution.assign_attributes(attributes.except(:start_now)) if attributes
      process_execution.started_at = Time.now.utc if attributes[:start_now]

      if process_execution.process_template
        if process_execution.document.nil?
          process_execution.document = process_execution.process_template.document
        end
      end

      process_execution.save
    end

    if success
      return process_execution, nil
    else
      return nil, process_execution.errors
    end
  end
end
