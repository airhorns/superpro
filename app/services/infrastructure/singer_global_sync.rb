require "securerandom"

module Infrastructure
  class SingerGlobalSync
    include SemanticLogger::Loggable

    GLOBAL_SYNCS = {
      "snowplow_kafka" => {
        importer: "kafka",
        config: {
          bootstrap_servers: Rails.configuration.kafka[:bootstrap_servers],
          topic: "snowplow-production-enriched",
          deserializer: "snowplow_analytics_sdk.event_transformer.transform",
          consumer_config: {
            security_protocol: "SASL_SSL",
            sasl_mechanism: "PLAIN",
            sasl_plain_username: Rails.configuration.kafka[:sasl_plain_username],
            sasl_plain_password: Rails.configuration.kafka[:sasl_plain_password],
            api_version: "1.0.0",
          },
          schema: JSON.parse(File.read(Rails.root.join("app", "services", "infrastructure", "snowplow_enriched_event.json"))),
        },
        transform: {},
      },
    }

    def self.run_in_background(global_sync_key)
      args = [{ global_sync_key: global_sync_key }]

      if Rails.env.production?
        KubernetesClient.client.run_background_job_in_k8s(Infrastructure::GlobalSingerSyncJob, args)
      else
        Infrastructure::GlobalSingerSyncJob.enqueue(*args)
      end
    end

    def initialize(key)
      @key = key
    end

    def reset_state
      state_record = current_state_record
      if state_record
        state_record.state = {}
        state_record.save!
      end
    end

    def sync
      attempt_record = SingerGlobalSyncAttempt.create!(key: @key, started_at: Time.now.utc, last_progress_at: Time.now.utc)
      state_record = current_state_record || SingerGlobalSyncState.create!(key: @key, state: {})
      state = state_record.state || {}

      details = GLOBAL_SYNCS.fetch(@key)

      logger.tagged global_sync_key: @key, import_id: attempt_record.id do
        begin
          logger.info "Beginning Singer sync for global", importer: details.fetch(:importer)

          SingerImporterClient.client.import(
            details.fetch(:importer),
            config: details.fetch(:config),
            state: state,
            url_params: { import_id: attempt_record.id },
            transform: details.fetch(:transform),
            on_state_message: Proc.new do |new_state|
              SingerGlobalSyncAttempt.transaction do
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

    def current_state_record
      SingerGlobalSyncState.where(key: @key).first
    end
  end
end
