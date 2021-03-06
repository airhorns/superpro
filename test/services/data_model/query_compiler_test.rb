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

  test "it can compile a simple query with a limit" do
    sql = compile(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "average", id: "total_weight" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled_status" }],
      limit: 10,
    )

    assert_matches_snapshot sql
  end

  test "it can compile a query with sql measures against the orders fact table" do
    sql = compile(
      measures: [{ model: "Sales::OrderFacts", field: "order_count", id: "order_count" }],
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

  test "it can compile a query with a set of filters" do
    sql = compile(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_year", id: "created_at_date" }],
      filters: [{ id: "created_at_date", operator: "equals", values: ["2000"] }, { id: "total_price", operator: "greater_than", values: [100] }],
    )

    assert_matches_snapshot sql
  end

  test "it can compile a query with join to a dimension" do
    sql = compile(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "customer_first_name", id: "first_name" }],
    )

    assert_matches_snapshot sql
  end

  test "it can execute a query with percentile operators" do
    assert_matches_snapshot compile(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "p90", id: "total_price" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" }],
    )
  end

  test "it can select from a complicated custom exrepssion" do
    assert_matches_snapshot compile(
      measures: [{ model: "Sales::RepurchaseIntervalFacts", field: "early_repurchase_rate", id: "early_repurchase_rate" }],
      dimensions: [{ model: "Sales::RepurchaseIntervalFacts", field: "order_date", operator: "date_trunc_day", id: "date" }],
    )
  end

  test "it can select measures provided by dimensions while joining in the dimension" do
    assert_matches_snapshot compile(
      measures: [
        {
          model: "Sales::OrderProductLineFacts",
          field: "customer_previous_3_month_revenue",   # comes from a joined in dimension where the field is actually a dimension, but we treat it as a measure here
          operator: "average",
          id: "previous_3_month_revenue",
        },
      ],
      dimensions: [{ model: "Sales::OrderProductLineFacts", field: "variant_product_type", id: "type" }],
    )
  end

  def compile(query_spec)
    assert DataModel::Query.new(@account, SuperproWarehouse, query_spec).validate!
    DataModel::QueryCompiler.new(@account, SuperproWarehouse, query_spec).sql
  end
end
