# frozen_string_literal: true

module GraphQLTestHelper
  def assert_no_graphql_errors(result)
    assert_nil result["errors"]
  end
end
