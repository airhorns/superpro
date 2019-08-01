require "securerandom"

module Infrastructure
  class SingerConnectionSync
    include SemanticLogger::Loggable

    def initialize(account)
      @account = account
    end

    def reset_state(connection)
      state_record = connection.singer_sync_state
      if state_record
        state_record.state = {}
        state_record.save!
      end
    end

    def sync(connection)
      if !connection.strategy_singer?
        raise RuntimeError.new("Trying to singer sync a connection that isn't using singer for sync. #{connection}")
      end

      state_record = connection.singer_sync_state || connection.build_singer_sync_state(account: @account)
      state = state_record.state || {}

      importer = importer_for_connection(connection)
      config = config_for_connection(connection)
      import_tag = SecureRandom.uuid

      logger.tagged connection_id: connection.id, importer: importer, import_id: import_tag do
        logger.info "Beginning Singer sync for connection"
        SingerImporterClient.client.import(importer, config, state, { import_id: import_tag }) do |new_state|
          state_record.state = new_state
          state_record.save!
          logger.info "State updated to #{new_state}"
        end

        logger.info "Import completed successfully"
      end
    end

    def importer_for_connection(connection)
      case connection.integration
      when ShopifyShop then "shopify"
      else raise RuntimeError.new("Unknown connection integration class #{connection.integration.class} for connection #{connection.id}")
      end
    end

    def config_for_connection(connection)
      case connection.integration
      when ShopifyShop then { "private_app_api_key" => connection.integration.api_key, "private_app_password" => connection.integration.password, "shop" => connection.integration.shopify_domain, "start_date" => "2019-07-27" }
      else raise RuntimeError.new("Unknown connection integration class #{connection.integration.class} for connection #{connection.id}")
      end
    end
  end
end
