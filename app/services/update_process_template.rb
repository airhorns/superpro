class UpdateProcessTemplate
  def initialize(account, user)
    @account = account
    @user = user
  end

  def update(process_template, attributes)
    success = ProcessTemplate.transaction do
      process_template.assign_attributes(attributes)
      process_template.save
    end

    if success
      return process_template, nil
    else
      return nil, process_template.errors
    end
  end
end
