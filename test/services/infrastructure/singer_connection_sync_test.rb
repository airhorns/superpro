require "test_helper"

class Infrastructure::SingerConnectionSyncTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @sync = Infrastructure::SingerConnectionSync.new(@account)
    SecureRandom.stubs(:uuid).returns("one", "two", "three")
  end

  test "it can sync a shopify store" do
    connection = create(:shopify_hrsn_connection, account: @account)
    @sync.sync(connection)

    connection.reload
    assert_not_nil connection.singer_sync_state
    assert_not_nil connection.singer_sync_state.state["bookmarks"]

    @sync.sync(connection)

    connection.reload
    assert_not_nil connection.singer_sync_state
    assert_not_nil connection.singer_sync_state.state["bookmarks"]
  end
end
