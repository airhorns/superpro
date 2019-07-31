require "test_helper"

class Connections::PlaidAuthTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @connect_shopify = Connections::ConnectShopify.new(@account, @account.creator)
  end

  test "it can connect a private shopify app" do
    shop, errors = @connect_shopify.connect_private_app("f7cce5f3a9cba33093e5766d4fc0ee56", "c313f81fe851b89b369f797cf99e3476", "hrsn.myshopify.com")
    assert_nil errors
    assert_not_nil shop
  end
end
