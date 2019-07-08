class Todos::UpdateProcessExecution
  def initialize(account, user)
    @account = account
    @user = user
  end

  def update(process_execution, attributes)
    success = ProcessExecution.transaction do
      process_execution.assign_attributes(attributes)
      Todos::StatsTracker.track_all(process_execution)
      process_execution.save
    end

    if success
      return process_execution, nil
    else
      return nil, process_execution.errors
    end
  end
end
