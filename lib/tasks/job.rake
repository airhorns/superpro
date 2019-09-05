namespace :job do
  desc "Run a Que job inline. Used by other infrastructure components"
  task :run_inline, [:job_class, :args_json] => :environment do |_t, args|
    klass = args[:job_class].constantize
    job_args = JSON.parse(args[:args_json])
    Rails.logger.info "Running job inline", job_class: job_class, args: job_args
    klass.run(*job_args)
  end
end
