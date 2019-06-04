ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include GraphQLTestHelper

  # Run tests in parallel with specified workers
  if ENV["CI"] or ENV["PARALLEL"]
    parallelize(workers: :number_of_processors)
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
