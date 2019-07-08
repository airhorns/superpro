require "test_helper"

CREATE_SCRATCHPAD_MUTATION = <<~QUERY
  mutation createScratchpad {
    createScratchpad {
      scratchpad {
        id
        name
        document
      }
      errors {
        field
        fullMessage
      }
    }
  }
QUERY

UPDATE_SCRATCHPAD_MUTATION = <<~QUERY
  mutation updateScratchpad($id: ID!, $attributes: ScratchpadAttributes!) {
    updateScratchpad(id: $id, attributes: $attributes) {
      scratchpad {
        id
        name
        document
      }
      errors {
        field
        fullMessage
      }
    }
  }
QUERY

class ScratchpadIntegrationTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @context = { current_account: @account, current_user: @account.creator }
  end

  test "it can create and update scratchpad" do
    result = FlurishAppSchema.execute(CREATE_SCRATCHPAD_MUTATION, context: @context)
    assert_no_graphql_errors result
    assert_nil result["data"]["createScratchpad"]["errors"]
    assert_not_nil result["data"]["createScratchpad"]["scratchpad"]["id"]
    scratchpad = Scratchpad.find(result["data"]["createScratchpad"]["scratchpad"]["id"])
    assert_equal @account, scratchpad.account
    assert_equal @account.creator, scratchpad.creator
    assert_not_nil scratchpad.document
    assert_not_nil scratchpad.name

    result = FlurishAppSchema.execute(UPDATE_SCRATCHPAD_MUTATION, context: @context, variables: ActionController::Parameters.new({
                                                                    id: scratchpad.id.to_s,
                                                                    attributes: { document: {
                                                                      object: "document",
                                                                      data: {},
                                                                      nodes: [
                                                                        {
                                                                          object: "block",
                                                                          type: "heading-one",
                                                                          nodes: [
                                                                            {
                                                                              object: "text",
                                                                              text: "A new title",
                                                                            },
                                                                          ],
                                                                        },
                                                                      ],
                                                                    } },
                                                                  }))
    assert_no_graphql_errors result
    assert_nil result["data"]["updateScratchpad"]["errors"]
    scratchpad.reload
    assert_equal "A new title", scratchpad.name
  end
end
