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
      attempt_record = @account.singer_sync_attempts.create!(connection: connection, started_at: Time.now.utc)

      logger.tagged connection_id: connection.id, importer: importer, import_id: attempt_record.id do
        logger.info "Beginning Singer sync for connection"

        begin
          SingerImporterClient.client.import(importer, config, state, { import_id: attempt_record.id }, transform_for_connection(connection)) do |new_state|
            state_record.state = new_state
            state_record.save!
            logger.info "State updated to #{new_state}"
          end
        rescue StandardError => e
          attempt_record.update!(finished_at: Time.now.utc, success: false, failure_reason: e.message)
          raise
        end

        logger.info "Import completed successfully"
        attempt_record.update!(finished_at: Time.now.utc, success: true)
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
      when ShopifyShop then { "private_app_api_key" => connection.integration.api_key, "private_app_password" => connection.integration.password, "shop" => connection.integration.shopify_domain, "start_date" => "2017-01-01" }
      else raise RuntimeError.new("Unknown connection integration class #{connection.integration.class} for connection #{connection.id}")
      end
    end

    def transform_for_connection(connection)
      field_values = { account_id: @account.id }

      case connection.integration
      when ShopifyShop then field_values[:shop_id] = connection.integration.shop_id
      else raise RuntimeError.new("Unknown connection integration class #{connection.integration.class} for connection #{connection.id}")
      end

      field_values
    end
  end
end
