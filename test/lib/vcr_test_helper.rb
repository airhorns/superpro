# frozen_string_literal: true

# Setup some env vars that devs might pass in for VCR to record real requests, then replace them with VCR's sensitive data filters so
# the cassettes are safe to commit to Git.
ENV["GA_OAUTH_ACCESS_TOKEN"] ||= "test_access_token"
ENV["GA_OAUTH_REFRESH_TOKEN"] ||= "test_refresh_token"
ENV["SHOPIFY_OAUTH_ACCESS_TOKEN"] ||= "test_access_token"
ENV["KAFKA_SASL_PLAIN_PASSWORD"] ||= "test_kafka_password"
ENV["FB_OAUTH_ACCESS_TOKEN"] ||= "test_access_token"
QUERY_PARAM_MATCH_EXCLUSIONS = ["appsecret_proof"].freeze

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("test", "vcr_cassettes").to_s
  config.allow_http_connections_when_no_cassette = true
  config.hook_into :webmock
  config.filter_sensitive_data("<GA_OAUTH_ACCESS_TOKEN>") { ENV["GA_OAUTH_ACCESS_TOKEN"] }
  config.filter_sensitive_data("<GA_OAUTH_REFRESH_TOKEN>") { ENV["GA_OAUTH_REFRESH_TOKEN"] }
  config.filter_sensitive_data("<FB_OAUTH_ACCESS_TOKEN>") { ENV["FB_OAUTH_ACCESS_TOKEN"] }
  config.filter_sensitive_data("<SHOPIFY_OAUTH_ACCESS_TOKEN>") { ENV["SHOPIFY_OAUTH_ACCESS_TOKEN"] }
  config.filter_sensitive_data("<KAFKA_SASL_PLAIN_PASSWORD>") { ENV["KAFKA_SASL_PLAIN_PASSWORD"] }
  config.filter_sensitive_data("<AUTHORIZATION>") do |interaction|
    interaction.request.headers.key?("Authorization") && interaction.request.headers["Authorization"].first
  end
  config.filter_sensitive_data("<KUBE_CLUSTER_ADDRESS>") { "kubernetes.docker.internal:6443" }

  config.register_request_matcher :less_sensitive_query do |request_a, request_b|
    params_a = Rack::Utils.parse_query(URI(request_a.uri).query)
    params_b = Rack::Utils.parse_query(URI(request_b.uri).query)
    params_a.except(*QUERY_PARAM_MATCH_EXCLUSIONS) == params_b.except(*QUERY_PARAM_MATCH_EXCLUSIONS)
  end
end

module VcrTestHelper
  extend ActiveSupport::Concern

  included do
    setup do
      ActionMailer::Base.deliveries.clear
      VCR.insert_cassette("#{self.class.name.underscore}/#{name.downcase}", match_requests_on: %i[method host path less_sensitive_query])
    end

    teardown do
      VCR.eject_cassette
    end
  end
end
