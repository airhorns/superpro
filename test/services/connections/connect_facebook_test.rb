# frozen_string_literal: true

require "test_helper"

class Connections::ConnectFacebookTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @connect = Connections::ConnectFacebook.new(@account, @account.creator)
    @ad_account = create(
      :facebook_ad_account,
      account: @account,
      creator: @account.creator,
      access_token: ENV["FB_OAUTH_ACCESS_TOKEN"],
      configured: false,
    )
  end

  test "it can list the ad accounts for an unconfigured ad_account" do
    accounts = @connect.list_ad_accounts(@ad_account)
    assert_not_nil accounts
    assert accounts.all? { |account| account[:id].present? }
    assert accounts.all? { |account| !account[:already_setup] }
  end

  test "it can select an account for an unconfigured ad account" do
    accounts = @connect.list_ad_accounts(@ad_account)
    @connect.select_account_id(@ad_account, accounts[0][:id])
    @ad_account.reload

    assert @ad_account.configured
    assert_not_nil @ad_account.fb_account_id
    assert_not_nil @ad_account.fb_account_name

    connection = @account.connections.where(integration: @ad_account).first
    assert_not_nil connection
    assert_not_nil connection.display_name
  end
end
