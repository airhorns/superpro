# frozen_string_literal: true

require "test_helper"

class Infrastructure::SingerConnectionSyncTest < ActiveSupport::TestCase
  setup do
    @account = create(:account, business_epoch: Time.now.utc - 1.day)
    @sync = Infrastructure::SingerConnectionSync.new(@account)
    @connection = create(:shopify_hrsn_connection, account: @account)

    # Reset this sequence so the IDs are the same for VCR every time
    ActiveRecord::Base.connection.execute(
      "ALTER SEQUENCE singer_sync_attempts_id_seq RESTART WITH 1"
    )
  end

  test "it can sync a shopify store" do
    assert_difference "SingerSyncAttempt.count", 1 do
      @sync.sync(@connection)
    end
    attempt = @connection.singer_sync_attempts.order("id DESC").first
    assert attempt.success
    assert_not_nil attempt.started_at
    assert_not_nil attempt.finished_at
    assert attempt.finished_at >= attempt.started_at

    @connection.reload
    assert_not_nil @connection.singer_sync_state
    assert_not_nil @connection.singer_sync_state.state["bookmarks"]

    assert_difference "SingerSyncAttempt.count", 1 do
      @sync.sync(@connection)
    end

    @connection.reload
    assert_not_nil @connection.singer_sync_state
    assert_not_nil @connection.singer_sync_state.state["bookmarks"]
  end

  test "it can sync a google analytics credential" do
    @connection = create(:google_analytics_connection, account: @account)
    assert_difference "SingerSyncAttempt.count", 1 do
      @sync.sync(@connection)
    end
    attempt = @connection.singer_sync_attempts.order("id DESC").first
    assert attempt.success
  end

  # test "it can sync a facebook ad account" do
  #   @connection = create(:facebook_ads_connection, account: @account)
  #   assert_difference "SingerSyncAttempt.count", 1 do
  #     @sync.sync(@connection)
  #   end
  #   attempt = @connection.singer_sync_attempts.order("id DESC").first
  #   assert attempt.success
  # end

  test "it tracks restclient exceptions as failures" do
    RestClient::Request.expects(:execute).once.raises(RestClient::ServerBrokeConnection)

    assert_difference "SingerSyncAttempt.count", 1 do
      assert_raises RestClient::ServerBrokeConnection do
        @sync.sync(@connection)
      end
    end

    attempt = @connection.singer_sync_attempts.order("id DESC").first
    assert_equal false, attempt.success
    assert_not_nil attempt.started_at
    assert_not_nil attempt.finished_at
    assert attempt.finished_at >= attempt.started_at
  end
end
