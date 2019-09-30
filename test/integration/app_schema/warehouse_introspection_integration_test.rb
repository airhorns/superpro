# frozen_string_literal: true

require "test_helper"

WAREHOUSE_INTROSPECTION_QUERY = <<~QUERY
  query WarehouseIntrospection {
    warehouseIntrospection {
      factTables {
        name
        measureFields {
          fieldName
          fieldLabel
          dataType
          allowsOperators
          requiresOperators
          defaultOperator
        }

        dimensionFields {
          fieldName
          fieldLabel
          dataType
          allowsOperators
        }
      }
      operators {
        key
      }
    }
  }
QUERY

class WarehouseQueryIntegrationTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @context = { current_user: @account.creator, current_account: @account }
  end

  test "it can query the warehouse for the introspection" do
    result = SuperproAppSchema.execute(WAREHOUSE_INTROSPECTION_QUERY, context: @context)
    assert_no_graphql_errors result
    assert result["data"]["warehouseIntrospection"]["factTables"]
    assert result["data"]["warehouseIntrospection"]["operators"]
  end
end
