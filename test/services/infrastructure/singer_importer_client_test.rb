# frozen_string_literal: true
require "test_helper"

class Infrastructure::SingerImporterClientTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @client = Infrastructure::SingerImporterClient.client
  end

  test "it can import a shopify store" do
    states = []

    @client.import(
      "shopify",
      config: {
        "start_date": "2019-09-15",
        "private_app_api_key": "f7cce5f3a9cba33093e5766d4fc0ee56",
        "private_app_password": "c313f81fe851b89b369f797cf99e3476",
        "shop": "hrsn.myshopify.com",
      },
      on_state_message: ->(state) { states << state },
    )

    assert_not states.empty?
    assert_not_nil states[-1]["bookmarks"]["orders"]
  end

  test "it raises when given incorrect configuration" do
    assert_raises do
      @client.import(
        "shopify",
        config: {
          "start_date": "2019-07-28",
          "private_app_api_key": "not-real",
          "private_app_password": "not-real",
          "shop": "hrsn.myshopify.com",
        },
      )
    end
  end

  # This test uses a doctored cassette to emulate the backend process dying early
  test "it raises when the response stream ends prematurely" do
    assert_raises(Infrastructure::SingerImporterClient::UncleanExitException) do
      @client.import(
        "shopify",
        config: {
          "start_date": "2019-09-15",
          "private_app_api_key": "f7cce5f3a9cba33093e5766d4fc0ee56",
          "private_app_password": "c313f81fe851b89b369f797cf99e3476",
          "shop": "hrsn.myshopify.com",
        },
      )
    end
  end
end
