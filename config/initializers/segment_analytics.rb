# frozen_string_literal: true

Analytics = Segment::Analytics.new(
  write_key: ENV["SEGMENT_BACKEND_WRITE_KEY"] || "bogus",
  on_error: proc { |_status, msg| Rails.logger.error("[segment-error] #{msg}") },
  max_queue_size: 10000,
  batch_size: 100,
  stub: !Rails.env.production?,
)

Segment::Analytics::Logging.logger = Logger.new(STDOUT)
Segment::Analytics::Logging.logger.level = :warn
