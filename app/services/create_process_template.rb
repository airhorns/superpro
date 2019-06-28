class CreateProcessTemplate
  def initialize(account, user)
    @account = account
    @user = user
  end

  def create(attributes = nil)
    process_template = @account.process_templates.build(name: "New Processs Template", document: {}, creator: @user)

    success = ProcessTemplate.transaction do
      process_template.assign_attributes(attributes) if attributes
      process_template.save
    end

    if success
      return process_template, nil
    else
      return nil, process_template.errors
    end
  end
end
