class Todos::CreateScratchpad
  DEFAULT_DOCUMENT = {
    object: "document",
    data: {},
    nodes: [
      {
        object: "block",
        type: "heading-one",
        nodes: [
          {
            object: "text",
            text: "New Scratchpad",
          },
        ],
      },
      {
        object: "block",
        type: "paragraph",
        nodes: [
          {
            object: "text",
            text: "",
          },
        ],
      },
    ],
  }

  def initialize(account, user)
    @account = account
    @user = user
  end

  def create(attributes = nil)
    attributes ||= {}
    scratchpad = @account.scratchpads.build(creator: @user, access_mode: "private", name: "New Scratchpad", document: DEFAULT_DOCUMENT)
    return Todos::UpdateScratchpad.new(@account, @user).update(scratchpad, attributes)
  end
end
