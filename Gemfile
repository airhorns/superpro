source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
ruby '2.6.2'

# Core web app
gem 'devise', github: "plataformatec/devise", ref: "19045a4"  # needed for rails 6 compat
gem 'devise_invitable'
gem 'discard'
gem 'graphiql-rails'
gem 'graphql'
gem 'graphql-batch', require: "graphql/batch"
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.0'
gem 'rack-cors'
gem 'rails', '6.0.0.rc1'
gem 'webpacker'

# Functionality
gem 'money-rails'
gem 'rrule'
gem 'rails-i18n'

# Integrations
gem 'omniauth'

# JSFarm
gem 'rest-client'
gem 'xxhash'

# Performance & Infrastructure
gem 'active_record_query_trace'
gem 'analytics-ruby', '~> 2.2.7', require: 'segment/analytics'
gem "annotate"
gem 'ar_transaction_changes'
gem "asset_sync"
gem "fog-google", '~> 1.9.1'
gem 'bcrypt', '~> 3.1.7'
gem 'bootsnap', '>= 1.1.0', require: false
gem "bullet", "~> 6.0.1"
gem "flipper"
gem "flipper-active_record"
gem "flipper-active_support_cache_store"
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
gem 'que-web'
gem 'redis', '~> 4.0'
gem 'request_store'
gem "safely"
gem "scenic"
gem "sentry-raven"
gem 'silencer'

# Admin
gem 'omniauth-google-oauth2'
gem 'trestle'
gem 'trestle-omniauth'

group :development, :test, :integration_test do
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
  gem 'web-console', github: 'rails/web-console'
end

group :test do
  gem 'timecop'
  gem 'minitest-ci', require: !ENV['CI'].nil?
  gem 'mocha'
  gem 'vcr'
end

group :deploy do
  gem 'kubernetes-deploy'
end