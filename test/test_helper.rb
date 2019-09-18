ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

# Setup some env vars that devs might pass in for VCR to record real requests, then replace them with VCR's sensitive data filters so
# the cassettes are safe to commit to Git.
ENV["GA_OAUTH_ACCESS_TOKEN"] ||= "test_access_token"
ENV["GA_OAUTH_REFRESH_TOKEN"] ||= "test_refresh_token"
ENV["KAFKA_SASL_PLAIN_PASSWORD"] ||= "test_kafka_password"

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("test", "vcr_cassettes").to_s
  config.allow_http_connections_when_no_cassette = true
  config.hook_into :webmock
  config.filter_sensitive_data("<GA_OAUTH_ACCESS_TOKEN>") { ENV["GA_OAUTH_ACCESS_TOKEN"] }
  config.filter_sensitive_data("<GA_OAUTH_REFRESH_TOKEN>") { ENV["GA_OAUTH_REFRESH_TOKEN"] }
  config.filter_sensitive_data("<KAFKA_SASL_PLAIN_PASSWORD>") { ENV["KAFKA_SASL_PLAIN_PASSWORD"] }
  config.filter_sensitive_data("<AUTHORIZATION>") do |interaction|
    interaction.request.headers.has_key?("Authorization") && interaction.request.headers["Authorization"].first
  end
  config.filter_sensitive_data("<KUBE_CLUSTER_ADDRESS>") { "kubernetes.docker.internal:6443" }
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include GraphQLTestHelper

  # Run tests in parallel with specified workers
  if ENV["CI"] or ENV["PARALLEL"]
    parallelize(workers: :number_of_processors)
  end

  setup do
    ActionMailer::Base.deliveries.clear
    VCR.insert_cassette("#{self.class.name.underscore}/#{name.downcase}")
  end

  teardown do
    VCR.eject_cassette
  end

  def with_synchronous_jobs
    old_value = Que::Job.run_synchronously
    Que::Job.run_synchronously = true
    yield
  ensure
    Que::Job.run_synchronously = old_value
  end

  def raise_on_unoptimized_queries
    old_enabled = Bullet.enable?
    Bullet.enable = true
    Bullet.raise = true
    yield
  ensure
    Bullet.enable = old_enabled
    Bullet.raise = false
  end
end
