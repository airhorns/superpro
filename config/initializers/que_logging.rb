require "que"

# Monkeypatch the Que logger to send log events with the event as the first parameter, and all it's semantic juicy goodness as keyword arguments to the semantic-logger gem
# for correct and pluggable formatting of the extra data.
module Que
  module Utils
    module Logging
      attr_accessor :logger, :internal_logger
      attr_writer :log_formatter

      def log(event:, level: :info, **extra)
        data = _default_log_data
        data.merge!(extra)

        SemanticLogger[Que].send(level, event, **data)
      end
    end
  end
end

Que.error_notifier = proc do |error, job|
  Que.logger.error(error.message, job)
  Raven.capture_exception(error, extra: job)
end

Que.logger = SemanticLogger[Que]
