# frozen_string_literal: true

require "test_helper"

class DataModel::QueryIntrospectionTest < ActiveSupport::TestCase
  setup do
    @account = stub(id: 10)
  end

  test "it introspects queries" do
    query = {
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "average", id: "total_weight" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled_status" }],
    }

    introspection = DataModel::QueryIntrospection.new(@account, SuperproWarehouse, query)
    assert_matches_snapshot JSON.pretty_generate(introspection.as_json)
  end

  test "it reports the output type of operators that change the type" do
    query = {
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", id: "created_at", operator: "date_part_day_of_week" }],
    }

    introspection = DataModel::QueryIntrospection.new(@account, SuperproWarehouse, query)
    assert_equal DataModel::Types::Number, introspection.as_json[:fields].detect { |field| field[:id] == "created_at" }[:data_type]
  end
end
