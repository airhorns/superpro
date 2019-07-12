ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("test", "vcr_cassettes").to_s
  config.hook_into :webmock
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
    VCR.insert_cassette(name)
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
