class CreateProcessTemplate
  DEFAULT_DOCUMENT = {
    document: {
      data: {},
      nodes: [
        {
          object: "block",
          type: "paragraph",
          nodes: [
            {
              object: "text",
              text: "<TBD>",
            },
          ],
        },
      ],
    },
  }

  def initialize(account, user)
    @account = account
    @user = user
  end

  def create(attributes = nil)
    process_template = @account.process_templates.build(name: "New Process Template", document: DEFAULT_DOCUMENT, creator: @user)

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
