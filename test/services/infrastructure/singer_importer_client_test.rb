require "test_helper"

class Infrastructure::SingerImporterClientTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @client = Infrastructure::SingerImporterClient.client
  end

  test "it can import a shopify store" do
    lines = 0
    @client.import("shopify", {
      "start_date": "2019-07-28",
      "private_app_api_key": "f7cce5f3a9cba33093e5766d4fc0ee56",
      "private_app_password": "c313f81fe851b89b369f797cf99e3476",
      "shop": "hrsn.myshopify.com",
    }) { |_state| lines += 1 }

    assert lines > 0
  end
end
