class Todos::DiscardProcessExecution
  def initialize(account, user)
    @account = account
    @user = user
  end

  def discard(process_execution)
    success = ProcessExecution.transaction do
      process_execution.discard
      true
    end

    if success
      return process_execution, nil
    else
      return nil, process_execution.errors
    end
  end
end
