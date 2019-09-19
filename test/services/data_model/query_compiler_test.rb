# frozen_string_literal: true

require "test_helper"

class DataModel::QueryCompilerTest < ActiveSupport::TestCase
  setup do
    @account = stub(id: 10)
  end

  test "it can compile a simple query against the orders fact table without dimensions" do
    sql = compile(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [],
    )

    assert_matches_snapshot sql
  end

  test "it can compile a simple query against the orders fact table with an ordering" do
    sql = compile(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [],
      orderings: [{ id: "total_price", direction: "asc" }],
    )

    assert_matches_snapshot sql
  end

  test "it can compile a simple query against the orders fact table" do
    sql = compile(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "average", id: "total_weight" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled_status" }],
    )

    assert_matches_snapshot sql
  end

  test "it can compile a time dimension query against the orders fact table" do
    sql = compile(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "created_at_date" }],
    )

    assert_matches_snapshot sql
  end

  def compile(query_spec)
    assert DataModel::QueryValidator.validate!(query_spec)
    DataModel::QueryCompiler.new(@account, SuperproWarehouse, query_spec).sql
  end
end
