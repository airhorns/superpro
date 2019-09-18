# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  include Que::ActiveJob::JobExtensions

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  # https://github.com/chanks/que/blob/master/docs/logging.md#logging-job-completion
  def log_level(_elapsed)
    :info
  end
end
