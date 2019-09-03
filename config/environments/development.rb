Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true
  config.public_file_server.enabled = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp", "caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}",
    }
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false

  # Send mail using the development aid, letter_opener
  # See https://github.com/fgrehm/letter_opener_web
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Whitelist docker-for-mac ips for web console
  config.web_console.permissions = ["172.18.0.0/16", "172.19.0.0/16"]

  # Development happens on a real domain that resolves to localhost through an nginx
  config.force_ssl = true

  config.cache_store = :redis_cache_store, { url: "redis://localhost:6379/0" }
  config.session_store :cache_store, key: "superpro_dev_sessions"

  # Always log to stdout in development. Rails somehow magically makes this happen for the webserver but not for other processes
  # like the jobs server
  STDOUT.sync = true
  if SemanticLogger.appenders.all? { |appender| appender.instance_variable_get(:@log) != STDOUT }
    config.semantic_logger.add_appender(io: STDOUT, level: config.log_level, formatter: config.rails_semantic_logger.format)
  end

  config.after_initialize do
    Bullet.enable = true
    Bullet.rails_logger = true
  end

  config.x.domains.app = "app.supo.dev"
  config.x.domains.admin = "admin.supo.dev"
  config.action_controller.asset_host = "assets.supo.dev"
  config.hosts << ".supo.dev"
  config.action_mailer.default_url_options = { host: config.x.domains.app }
end
