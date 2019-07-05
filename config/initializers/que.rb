Que.error_notifier = proc do |_error, job|
  Raven.capture_exception(exception, extra: { job: job })
end
