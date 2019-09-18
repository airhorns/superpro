source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
ruby '2.6.4'

# Core web app
gem 'devise', '~> 4.7.1'
gem 'devise_invitable'
gem 'discard'
gem 'graphiql-rails'
gem 'graphql'
gem 'graphql-batch', require: "graphql/batch"
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'rack-cors'
gem 'rails', '6.0.0'
gem 'webpacker'

# Functionality
gem 'money-rails'
gem 'rrule'
gem 'rails-i18n'

# Integrations
gem 'omniauth'
gem 'plaid'
gem 'shopify_api'
gem 'rest-client'
gem 'google-api-client'

# Performance & Infrastructure
gem 'active_record_query_trace'
gem 'analytics-ruby', '~> 2.2.7', require: 'segment/analytics'
gem "annotate"
gem 'ar_transaction_changes'
gem "asset_sync"
gem "fog-google", '~> 1.9.1'
gem 'bcrypt', '~> 3.1.7'
gem 'bootsnap', '>= 1.1.0', require: false
gem "bullet", "~> 6.0.2"
gem "flipper", '~> 0.16', github: 'mokhan/flipper', branch: 'rails-6'
gem 'flipper-active_record', '~> 0.16', github: 'mokhan/flipper', branch: 'rails-6'
gem 'flipper-active_support_cache_store', '~> 0.16', github: 'mokhan/flipper', branch: 'rails-6'
gem 'flipper-ui'
gem "google-cloud-storage", require: false
gem "health_check"
gem 'hiredis'
gem 'jwt'
gem "lru_redux"
gem "marginalia"
gem "mini_magick"
gem "oj"
gem "que", github: "chanks/que", ref: "5ddddd5ebac6153d7a683ef08c86bced8e03fb51"
gem "que-scheduler", github: "hlascelles/que-scheduler", branch: "que-1.0-compatibility"
gem "que-locks", github: "superpro-inc/que-locks", ref: "f2b72a0a5cfd8ed553530d998431017ac9fc8bb8", require: "que/locks"
gem 'que-web'
gem 'rails-middleware-extensions'
gem 'rails_semantic_logger'
gem 'redis', '~> 4.1'
gem 'request_store'
gem "safely"
gem "scenic"
gem "sentry-raven"
gem "honeycomb-beeline", '~> 1.0.1', require: false # needs custom requiring in order to set up middleware properly, see initializer
gem 'k8s-client'

# Admin
gem 'omniauth-google-oauth2'
gem 'trestle'
gem 'trestle-omniauth'

group :development, :test, :integration_test do
  gem 'awesome_print'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'letter_opener'
  gem 'letter_opener_web'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rcodetools'
  gem 'rufo'
  gem 'subprocess'
end

group :development do
  gem 'ejson'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'solargraph'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console'
end

group :test do
  gem 'timecop'
  gem 'minitest-ci', require: !ENV['CI'].nil?
  gem 'mocha'
  gem 'webmock'
  gem 'vcr'
end

group :deploy do
  gem 'kubernetes-deploy'
end