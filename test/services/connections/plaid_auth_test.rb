require "test_helper"

class Connections::PlaidAuthTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @plaid_auth = Connections::PlaidAuth.new(@account, @account.creator)
  end

  test "it can exchange a public token for an access token" do
    item = @plaid_auth.complete_link("public-sandbox-af1e934b-391c-4af3-a758-ee9aa85371a0")
    assert_not_nil item.item_id
    assert_not_nil item.access_token

    assert item.plaid_item_accounts.size > 0
    assert_not_nil item.plaid_item_accounts[0].name
    assert_not_nil item.plaid_item_accounts[0].type
    assert_not_nil item.plaid_item_accounts[0].subtype
  end
end
