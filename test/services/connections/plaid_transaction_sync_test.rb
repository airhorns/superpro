# frozen_string_literal: true

require "test_helper"

class Connections::PlaidTransactionSyncTest < ActiveSupport::TestCase
  setup do
    Timecop.freeze("2019-06-01")
    @account = create(:account)
    @plaid_auth = Connections::PlaidAuth.new(@account, @account.creator)
    @item = @plaid_auth.complete_link("public-sandbox-cc5963a4-a64a-4e42-9aee-3fb1d84f3fdd")
    @plaid_sync = Connections::PlaidTransactionSync.new(@account, @item)
  end

  test "it can sync transactions for the initial sync" do
    date_range = Connections::PlaidTransactionSync.date_range_for_initial_sync(@item)
    @plaid_sync.sync(*date_range)
    assert_equal 16, @account.plaid_transactions.count
  end

  test "it can sync transactions for the historical sync" do
    date_range = Connections::PlaidTransactionSync.date_range_for_historical_sync(@item)
    @plaid_sync.sync(*date_range)
    assert_equal 368, @account.plaid_transactions.count
  end
end
