require "test_helper"

CREATE_ACCOUNT_MUTATION = <<~QUERY
  mutation NewAccount($account: AccountAttributes!) {
    createAccount(account: $account) {
      account {
        id
        name
      }
      errors {
        field
        relativeField
        message
        fullMessage
        mutationClientId
      }
    }
  }
QUERY

class CreateAccountIntegrationTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @context = { current_user: @user }
  end

  test "it can create a new account without attributes" do
    result = FlurishAuthSchema.execute(CREATE_ACCOUNT_MUTATION, context: @context, variables: { account: { name: "A new account" } })
    assert_no_graphql_errors result
    assert_nil result["data"]["createAccount"]["errors"]

    new_account = Account.find(result["data"]["createAccount"]["account"]["id"])
    assert_not_nil new_account.name
  end
end
