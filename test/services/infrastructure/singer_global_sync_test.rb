# frozen_string_literal: true

require "test_helper"

class Infrastructure::SingerGlobalSyncTest < ActiveSupport::TestCase
  setup do
    # Reset this sequence so the IDs are the same for VCR every time
    ActiveRecord::Base.connection.execute(
      "ALTER SEQUENCE singer_global_sync_attempts_id_seq RESTART WITH 1"
    )
  end

  test "it can sync snowplow kafka" do
    @sync = Infrastructure::SingerGlobalSync.new("snowplow_kafka")
    assert_difference "SingerGlobalSyncAttempt.count", 1 do
      @sync.sync
    end
    attempt = SingerGlobalSyncAttempt.order("id DESC").first
    assert attempt.success
    assert_not_nil attempt.started_at
    assert_not_nil attempt.finished_at
    assert attempt.finished_at >= attempt.started_at

    state = SingerGlobalSyncState.find_by(key: "snowplow_kafka")
    assert_not_nil state.state["bookmarks"]
  end

  test "it can sync snowplow kafka for the bad events" do
    @sync = Infrastructure::SingerGlobalSync.new("snowplow_kafka_errors")
    assert_difference "SingerGlobalSyncAttempt.count", 1 do
      @sync.sync
    end
    attempt = SingerGlobalSyncAttempt.order("id DESC").first
    assert attempt.success
    assert_not_nil attempt.started_at
    assert_not_nil attempt.finished_at
    assert attempt.finished_at >= attempt.started_at

    state = SingerGlobalSyncState.find_by(key: "snowplow_kafka_errors")
    assert_not_nil state.state["bookmarks"]
  end
end
