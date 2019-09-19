# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.cache_store = :redis_cache_store, { driver: :hiredis, url: ENV.fetch("REDIS_URL") }
  config.session_store :cache_store, key: "superpro_production_sessions"

  # We use ejson instead of the master key
  config.require_master_key = false

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = true

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :gcs_production

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", :debug).to_sym

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :que
  config.active_job.queue_name_prefix = "superpro_production"

  config.action_mailer.perform_caching = false
  config.action_mailer.smtp_settings = {
    user_name: "apikey",
    password: ENV["SENDGRID_APIKEY"],
    domain: "superpro.io",
    address: "smtp.sendgrid.net",
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true,
  }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use semantic_logger logging setup to STDOUT
  STDOUT.sync = true
  config.rails_semantic_logger.add_file_appender = false
  config.rails_semantic_logger.format = :json
  config.semantic_logger.add_appender(io: STDOUT, level: config.log_level, formatter: config.rails_semantic_logger.format)

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Don't run yarn for prod commands since it can change whats installed depending on the environment, and we're in docker where it shouldn't matter.
  config.webpacker.check_yarn_integrity = false

  config.x.domains.app = "app.superpro.io"
  config.x.domains.admin = "admin.superpro.io"
  config.action_controller.asset_host = "assets.superpro.io"
  config.action_mailer.default_url_options = { host: config.x.domains.app, protocol: "https" }
end
