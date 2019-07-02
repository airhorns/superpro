class CreateProcessExecution
  def initialize(account, user)
    @account = account
    @user = user
  end

  def create(attributes = nil)
    process_execution = @account.process_executions.build(name: "New Process Execution", creator: @user)

    if attributes.delete(:start_now)
      attributes[:started_at] = Time.now.utc
    end

    if attributes[:process_template_id] && !attributes[:document]
      attributes[:document] = @account.process_templates.find(attributes[:process_template_id]).document
    end

    return UpdateProcessExecution.new(@account, @user).update(process_execution, attributes)
  end
end
