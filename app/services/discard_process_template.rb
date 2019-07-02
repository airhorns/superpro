class DiscardProcessTemplate
  def initialize(account, user)
    @account = account
    @user = user
  end

  def discard(process_template)
    success = ProcessTemplate.transaction do
      process_template.discard
      true
    end

    if success
      return process_template, nil
    else
      return nil, process_template.errors
    end
  end
end
