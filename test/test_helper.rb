ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

ENV["GA_OAUTH_ACCESS_TOKEN"] ||= "test_access_token"
ENV["GA_OAUTH_REFRESH_TOKEN"] ||= "test_refresh_token"

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("test", "vcr_cassettes").to_s
  config.hook_into :webmock
  config.filter_sensitive_data("<GA_OAUTH_ACCESS_TOKEN>") { ENV["GA_OAUTH_ACCESS_TOKEN"] }
  config.filter_sensitive_data("<GA_OAUTH_REFRESH_TOKEN>") { ENV["GA_OAUTH_REFRESH_TOKEN"] }
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
    VCR.insert_cassette("#{self.class.name.underscore}/#{name.downcase}", record: :none)
  end

  teardown do
    VCR.eject_cassette
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
