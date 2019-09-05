require "test_helper"

class Connections::ConnectGoogleAnalyticsTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @credential = create(
      :google_analytics_credential,
      account: @account,
      token: ENV["GA_OAUTH_ACCESS_TOKEN"],
      refresh_token: ENV["GA_OAUTH_REFRESH_TOKEN"],
      configured: false,
    )
    @connection = create(
      :google_analytics_connection,
      account: @account,
      integration: @credential,
    )
    @connect_ga = Connections::ConnectGoogleAnalytics.new(@account, @account.creator)
    assert_equal 1, GoogleAnalyticsCredential.all.size # validates factory setup
  end

  test "it can list the views for an unconfigured google analytics credential" do
    views = @connect_ga.list_views(@credential)
    assert_not_nil views
    assert_equal ({ :id => "200604105", :name => "All Web Site Data", :property_id => "UA-146176198-1", :property_name => "Marketing Brochure", :account_id => "146176198", :account_name => "Superpro", :already_setup => false }), superpro_view(views)
  end

  test "listing views for unconfigured google analytics credential shows which views are already setup" do
    old_credential = create(:google_analytics_credential, account: @account, view_id: 200604105)
    create(:google_analytics_connection, account: @account, integration: old_credential)

    views = @connect_ga.list_views(@credential)
    assert_not_nil views
    assert_equal ({ :id => "200604105", :name => "All Web Site Data", :property_id => "UA-146176198-1", :property_name => "Marketing Brochure", :account_id => "146176198", :account_name => "Superpro", :already_setup => true }), superpro_view(views)
  end

  test "listing views for unconfigured google analytics credential allows setting up views previously used on a discarded connection" do
    old_credential = create(:google_analytics_credential, account: @account, view_id: 200604105)
    old_connection = create(:google_analytics_connection, account: @account, integration: old_credential)

    Connections::DiscardConnection.new(@account, @account.creator).discard(old_connection)

    views = @connect_ga.list_views(@credential)
    assert_not_nil views
    assert_equal ({ :id => "200604105", :name => "All Web Site Data", :property_id => "UA-146176198-1", :property_name => "Marketing Brochure", :account_id => "146176198", :account_name => "Superpro", :already_setup => false }), superpro_view(views)
  end

  test "it can select a view for a credential" do
    views = @connect_ga.list_views(@credential)
    @connect_ga.select_view(@credential, superpro_view(views)[:id])
    @credential.reload

    assert @credential.configured
    assert_equal 200604105, @credential.view_id
    assert_equal "All Web Site Data", @credential.view_name
    assert_equal 146176198, @credential.ga_account_id
    assert_equal "Superpro", @credential.ga_account_name
    assert_equal 0, @credential.property_id
    assert_equal "Marketing Brochure", @credential.property_name

    connection = @account.connections.where(integration: @credential).first
    assert_not_nil connection
    assert_not_nil connection.display_name
  end

  private

  def superpro_view(views_list)
    views_list.detect { |view| view[:id] == "200604105" }
  end
end
