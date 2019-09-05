require "test_helper"

class Connections::DiscardConnectionTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @discarder = Connections::DiscardConnection.new(@account, @account.creator)
  end

  test "it can discard a connection" do
    @connection = create(:shopify_hrsn_connection)
    @discarder.discard(@connection)
    @connection.reload

    assert @connection.discarded?
    assert_equal false, @connection.enabled
  end
end
