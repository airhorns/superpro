# frozen_string_literal: true

require "securerandom"

module Infrastructure
  class SingerConnectionSync
    include SemanticLogger::Loggable

    def self.run_in_background(connection)
      args = [{ connection_id: connection.id }]
      if Rails.env.production?
        KubernetesClient.client.run_background_job_in_k8s(Infrastructure::SyncSingerConnectionJob, args)
      else
        Infrastructure::SyncSingerConnectionJob.enqueue(*args)
      end
    end

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
        raise "Trying to singer sync a connection that isn't using singer for sync. #{connection}"
      end

      attempt_record = @account.singer_sync_attempts.create!(connection: connection, started_at: Time.now.utc, last_progress_at: Time.now.utc)
      state_record = connection.singer_sync_state || connection.build_singer_sync_state(account: @account)
      state = state_record.state || {}

      logger.tagged connection_id: connection.id, import_id: attempt_record.id do
        begin
          prepare_integration(connection)
          importer = importer_for_connection(connection)
          config = config_for_connection(connection)

          logger.info "Beginning Singer sync for connection", importer: importer

          SingerImporterClient.client.import(
            importer,
            config: config,
            state: state,
            url_params: { import_id: attempt_record.id },
            transform: transform_for_connection(connection),
            on_state_message: proc do |new_state|
              SingerSyncAttempt.transaction do
                state_record.state = new_state
                state_record.save!
                attempt_record.update!(last_progress_at: Time.now.utc)
              end
              logger.info "State updated to #{new_state}"
            end,
          )
        rescue StandardError => e
          attempt_record.update!(finished_at: Time.now.utc, success: false, failure_reason: e.message)
          raise
        end

        logger.info "Import completed successfully"
        attempt_record.update!(finished_at: Time.now.utc, success: true)
      end
    end

    def prepare_integration(connection)
      case connection.integration
      when GoogleAnalyticsCredential
        ga_credential = connection.integration
        Connections::ConnectGoogleAnalytics.new(@account, ga_credential.creator).refresh_access_token(ga_credential)
      end
    end

    def importer_for_connection(connection)
      case connection.integration
      when ShopifyShop then "shopify"
      when GoogleAnalyticsCredential then "google-analytics"
      when FacebookAdAccount then "facebook"
      else raise "Unknown connection integration class #{connection.integration.class} for connection #{connection.id}"
      end
    end

    def config_for_connection(connection)
      case connection.integration
      when ShopifyShop
        config = {
          "shop" => connection.integration.shopify_domain,
          "start_date" => start_date,
        }
        if connection.integration.access_token
          config["api_key"] = connection.integration.access_token
        else
          config["private_app_api_key"] = connection.integration.api_key
          config["private_app_password"] = connection.integration.password
        end
        config
      when GoogleAnalyticsCredential
        {
          oauth_credentials: {
            access_token: connection.integration.token,
            refresh_token: connection.integration.refresh_token,
            client_id: Rails.configuration.google[:google_oauth_client_id],
            client_secret: Rails.configuration.google[:google_oauth_client_secret],
          },
          view_id: connection.integration.view_id.to_s,
          quota_user: "sp-accountid-#{connection.account_id}",
          start_date: start_date,
        }
      when FacebookAdAccount
        {
          access_token: connection.integration.access_token,
          account_id: connection.integration.fb_account_id.sub("act_", ""),
          start_date: start_date,
        }
      else
        raise "Unknown connection integration class #{connection.integration.class} for connection #{connection.id}"
      end
    end

    def transform_for_connection(connection)
      field_values = { account_id: @account.id }

      case connection.integration
      when ShopifyShop then field_values[:shop_id] = connection.integration.shop_id
      when GoogleAnalyticsCredential then field_values[:view_id] = connection.integration.view_id
      when FacebookAdAccount then field_values[:fb_account_id] = connection.integration.fb_account_id
      else raise "Unknown connection integration class #{connection.integration.class} for connection #{connection.id}"
      end

      field_values
    end

    def start_date
      @account.business_epoch.strftime("%Y-%m-%d")
    end
  end
end
