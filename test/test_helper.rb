# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include GraphQLTestHelper
  include VcrTestHelper

  # Run tests in parallel with specified workers
  if ENV["CI"] || ENV["PARALLEL"]
    parallelize(workers: :number_of_processors)
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

  def assert_string_like(expected, actual)
    assert_equal expected.gsub(/\s+/, " ").strip, actual.gsub(/\s+/, " ").strip
  end
end
