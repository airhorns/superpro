# frozen_string_literal: true

module Connections
  class ShopifyScriptTagManager
    include SemanticLogger::Loggable

    DESIRED_SCRIPT_TAG_ATTRIBUTES = {
      src: "https://sp-assets.superpro.io/shopify-script-tag.js",
      event: "onload",
      display_scope: "all",
    }.freeze

    def self.ensure_connection_setup_in_background(connection)
      if Flipper["feature.shopify_script_tags"].enabled?(connection.account)
        Connections::EnsureShopifyShopScriptTagSetupJob.enqueue(shopify_shop_id: connection.integration_id)
      end
    end

    def self.ensure_shop_setup(shopify_shop)
      self.new(shopify_shop.account).ensure_script_tag_exists(shopify_shop)
    end

    def initialize(account)
      @account = account
    end

    def ensure_script_tag_exists(shopify_shop)
      ShopifyShopSession.with_shop(shopify_shop) do
        script_tags = ShopifyAPI::ScriptTag.all
        existing = script_tags.detect { |script_tag| DESIRED_SCRIPT_TAG_ATTRIBUTES <= script_tag.attributes }

        if existing
          logger.info "Script tag already existed, all is well", script_tag_id: existing.id
        else
          script_tags.each do |tag|
            logger.info "Deleting outdated script tag", script_tag_id: tag.id
            ShopifyAPI::ScriptTag.delete(tag.id)
          end

          new_tag = ShopifyAPI::ScriptTag.create(DESIRED_SCRIPT_TAG_ATTRIBUTES)
          unless new_tag.persisted?
            raise new_tag.errors.full_messages.to_sentence
          end
          shopify_shop.update!(script_tag_setup_at: Time.now.utc)

          logger.info "Created new script tag", script_tag_id: new_tag.id
        end
      end
    end
  end
end
