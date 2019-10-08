# frozen_string_literal: true

require "test_helper"

WAREHOUSE_QUERY_QUERY = <<~QUERY
  query WarehouseQuery($query: JSONScalar!, $pivot: JSONScalar) {
    warehouseQuery(query: $query, pivot: $pivot) {
      records
      outputIntrospection {
        measures {
          id
          dataType
          label
          sortable
          pivotGroupId
        }
        dimensions {
          id
          dataType
          label
          sortable
        }
      }
      errors
    }
  }
QUERY

class WarehouseQueryIntegrationTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @context = { current_user: @account.creator, current_account: @account }
  end

  test "it can query the warehouse" do
    result = SuperproAppSchema.execute(WAREHOUSE_QUERY_QUERY, context: @context, variables: ActionController::Parameters.new(
                                                                query: {
                                                                  measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "sum", id: "total_weight" }],
                                                                  dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled" }],
                                                                },
                                                              ))
    assert_no_graphql_errors result
    assert_nil result["data"]["warehouseQuery"]["errors"]
    assert result["data"]["warehouseQuery"]["records"]
    assert result["data"]["warehouseQuery"]["outputIntrospection"]
  end

  test "it can query the warehouse with a pivot" do
    result = SuperproAppSchema.execute(WAREHOUSE_QUERY_QUERY, context: @context, variables: ActionController::Parameters.new(
                                                                query: {
                                                                  measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
                                                                  dimensions: [
                                                                    { model: "Sales::OrderFacts", field: "created_at", id: "created_at", operator: "date_trunc_day" },
                                                                    { model: "Sales::OrderFacts", field: "cancelled", id: "cancelled" },
                                                                  ],
                                                                },
                                                                pivot: {
                                                                  id: "test-pivot",
                                                                  measure_ids: ["total_price"],
                                                                  pivot_field_ids: ["cancelled"],
                                                                },
                                                              ))
    assert_no_graphql_errors result
    assert_nil result["data"]["warehouseQuery"]["errors"]
    assert result["data"]["warehouseQuery"]["records"]
    assert result["data"]["warehouseQuery"]["outputIntrospection"]
  end
end
