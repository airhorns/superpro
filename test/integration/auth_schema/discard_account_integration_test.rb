# frozen_string_literal: true

require "test_helper"

DISCARD_ACCOUNT_MUTATION = <<~QUERY
  mutation DiscardAccount($accountId: ID!) {
    discardAccount(id: $accountId) {
      account {
        id
        name
        discarded
      }
      errors {
        field
        message
      }
    }
  }
QUERY

class DiscardAccountIntegrationTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @account = create(:account, creator: @user)
    @context = { current_user: @user }
  end

  test "it can discard an account" do
    result = SuperproAuthSchema.execute(DISCARD_ACCOUNT_MUTATION, context: @context, variables: { accountId: @account.id })
    assert_no_graphql_errors result
    assert_nil result["data"]["discardAccount"]["errors"]

    assert result["data"]["discardAccount"]["account"]["discarded"]
    account = Account.find(result["data"]["discardAccount"]["account"]["id"])
    assert account.discarded?
  end
end
