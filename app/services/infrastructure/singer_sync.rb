require "securerandom"

class Infrastructure::SingerConnectionSync
  include SemanticLogger::Loggable

  def initialize(account)
    @account = account
  end

  def sync(connection, force_state = nil, reset_state = nil)
    if !connection.singer_strategy?
      raise RuntimeError.new("Trying to singer sync a connection that isn't using singer for sync. #{connection}")
    end

    state_record = connection.singer_sync_state || connection.build_singer_sync_state(account: @account)
    state = state_record.state
    if !state || reset_state
      state = {}
    end

    importer = importer_for_connection(connection)
    config = config_for_connection(connection)

    logger.tagged connection_id: connection.id, importer: importer, import: SecureRandom.uuid do
      logger.info "Beginning Singer sync for connection",
                  SingerImporterClient.import(importer, config) do |state|
        state_record.state = state
        state_record.save!
        logger.info "State updated to #{state}"
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
    when ShopifyShop then { "private_app_api_key" => connection.integration.api_key, "private_app_password" => connection.integration.password, "shop" => connection.integration.shopify_domain }
    else raise RuntimeError.new("Unknown connection integration class #{connection.integration.class} for connection #{connection.id}")
    end
  end
end
