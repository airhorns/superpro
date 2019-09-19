# frozen_string_literal: true

require "test_helper"

class DataModel::QueryIntrospectionTest < ActiveSupport::TestCase
  setup do
    @account = stub(id: 10)
  end

  test "it pulls out datatypes by id for queries" do
    query = {
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "average", id: "total_weight" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled_status" }],
    }

    introspection = DataModel::QueryIntrospection.new(@account, SuperproWarehouse, query)
    assert_equal({ "total_price" => "currency", "total_weight" => "weight", "cancelled_status" => "boolean" }, introspection.as_json[:types])
  end
end
