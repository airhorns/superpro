# frozen_string_literal: true

require "test_helper"

module Connections
  class ShopifyScriptTagManagerTest < ActiveSupport::TestCase
    setup do
      @account = create(:account)
      Flipper["feature.shopify_script_tags"].enable(@account)
      @shop = create(:sole_destroyer_shopify_shop, account: @account)
      @connection = create(:shopify_connection, integration: @shop)

      ShopifyShopSession.with_shop(@shop) do
        ShopifyAPI::ScriptTag.all.each do |tag|
          ShopifyAPI::ScriptTag.delete(tag.id)
        end
        assert_equal 0, ShopifyAPI::ScriptTag.all.size
      end
    end

    test "it can create a script tag" do
      assert_nil @shop.script_tag_setup_at

      # Create the tag for the first time
      ShopifyScriptTagManager.ensure_shop_setup(@shop)

      @shop.reload
      assert_not_nil @shop.script_tag_setup_at

      ShopifyShopSession.with_shop(@shop) do
        assert_equal 1, ShopifyAPI::ScriptTag.all.size
      end

      # Run the same code again to verify its idempotent
      ShopifyScriptTagManager.ensure_shop_setup(@shop)

      ShopifyShopSession.with_shop(@shop) do
        assert_equal 1, ShopifyAPI::ScriptTag.all.size
      end
    end

    test "it enqueues a background job and runs it to create a script tag from the helper method" do
      with_synchronous_jobs do
        assert_nil @shop.script_tag_setup_at

        ShopifyScriptTagManager.ensure_connection_setup_in_background(@connection)

        @shop.reload
        assert_not_nil @shop.script_tag_setup_at

        ShopifyShopSession.with_shop(@shop) do
          assert_equal 1, ShopifyAPI::ScriptTag.all.size
        end
      end
    end
  end
end
