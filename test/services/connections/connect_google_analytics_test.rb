require "test_helper"

class Connections::ConnectGoogleAnalyticsTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @credential = create(
      :google_analytics_credential,
      account: @account,
      token: "ya29.GlxsB1E2fIpvkcY5zVgpYM0fn9bJh5LXQ1mpvmIflKO9Nrad_UWbDUDzmYW22gpXfD1QLBbx4xeWzxvHHI0niWKSuxSlvmCN30_xaTV_UGP9d0EoowLkLmiDGPj2cw",
      refresh_token: "ya29.GlxsB1E2fIpvkcY5zVgpYM0fn9bJh5LXQ1mpvmIflKO9Nrad_UWbDUDzmYW22gpXfD1QLBbx4xeWzxvHHI0niWKSuxSlvmCN30_xaTV_UGP9d0EoowLkLmiDGPj2cw",
      configured: false,
    )
    @connect_ga = Connections::ConnectGoogleAnalytics.new(@account, @account.creator)
  end

  test "it can list the views for an unconfigured google analytics credential" do
    views = @connect_ga.list_views(@credential)
    assert_not_nil views
    assert_equal ({ :id => "127652462", :name => "All Web Site Data", :property_id => "UA-82477248-1", :property_name => "main website", :account_id => "82477248", :account_name => "noraswimwear", :already_setup => false }), views[0]
  end

  test "it can select a view for a credential" do
    views = @connect_ga.list_views(@credential)
    @connect_ga.select_view(@credential, views[0][:id])
    @credential.reload
    assert @credential.configured
    assert_equal 127652462, @credential.view_id
    assert_equal "whatever", @credential.view_name
    assert_equal 123, @credential.account_id
    assert_equal "whatever", @credential.account_name
    assert_equal 123, @credential.property_id
    assert_equal "whatever", @credential.property_name
  end
end
