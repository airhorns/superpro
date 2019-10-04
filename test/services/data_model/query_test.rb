# frozen_string_literal: true

require "test_helper"

class DataModel::QueryTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
  end

  test "it can execute a simple query against the orders fact table" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "sum", id: "total_weight" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled" }],
    )

    assert_equal [], result
  end

  test "it can execute a query with sql measures against the orders fact table" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "order_count", id: "order_counts" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled" }],
    )

    assert_equal [], result
  end

  test "it can execute a query that generates very long alias names" do
    result = run_query(
      measures: [{ model: "Sales::RepurchaseIntervalFacts", field: "count", id: "count" }],
      dimensions: [
        { model: "Sales::RepurchaseIntervalFacts", field: "days_since_previous_order_bucket_label", id: "days_since_previous_order" },
      ],
    )

    assert_equal [], result
  end

  test "it can execute a query against only dimensions" do
    result = run_query(
      measures: [],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" }],
    )

    assert_equal [], result
  end

  test "it can execute a query with time dimension operators" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "sum", id: "total_weight" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" }],
    )

    assert_equal [], result
  end

  test "it can execute a query with percentile operators" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "p90", id: "total_price" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" }],
    )

    assert_equal [], result
  end

  test "it can execute a query with an ordering" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", id: "total_price" }],
      dimensions: [],
      orderings: [{ id: "total_price", direction: "asc" }],
    )

    assert_equal [{ "total_price" => nil }], result
  end

  test "it can execute a query with a filter on an id field" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", id: "total_price" }],
      dimensions: [],
      filters: [{ id: "total_price", operator: "greater_than", values: [100] }],
    )

    assert_equal [], result
  end

  test "it can execute a query with a filter on a not-selected field" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_weight", id: "total_weight" }],
      dimensions: [],
      filters: [{ field: { model: "Sales::OrderFacts", field: "total_price", id: "total_price" }, operator: "greater_than", values: [100] }],
    )

    assert_equal [], result
  end

  test "it can execute a query with a filter on a datetime" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", id: "total_price", operator: "sum" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" }],
      filters: [{ id: "date", operator: "greater_than", values: ["2019-08-26T16:48:51.491-04:00"] }],
    )

    assert_equal [], result
  end

  test "it can execute a query with a filter on nulls" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", id: "total_price", operator: "sum" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", operator: "date_trunc_day", id: "date" }],
      filters: [{ id: "date", operator: "is_not_null" }],
    )

    assert_equal [], result
  end

  test "it can execute a query with a join to a dimension" do
    result = run_query(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "customer_first_name", id: "first_name" }],
    )

    assert_equal [], result
  end

  test "it doesnt allow queries on one account to find data from another" do
    other_account = create(:account)
    create(:shopify_shop, name: "Alpha", account: @account)
    create(:shopify_shop, name: "Beta", account: @account)
    create(:shopify_shop, name: "Gamma", account: other_account)

    spec = {
      measures: [],
      dimensions: [{ model: "Meta::ShopifyShopFacts", field: "name", id: "name" }],
      orderings: [{ id: "name", direction: "asc" }],
    }

    assert_equal [{ "name" => "Alpha" }, { "name" => "Beta" }], run_query(spec)
    assert_equal [{ "name" => "Gamma" }], DataModel::Query.new(other_account, SuperproWarehouse, spec).run
  end

  test "it can select from a complicated custom exrepssion" do
    result = run_query(
      measures: [{ model: "Sales::RepurchaseIntervalFacts", field: "early_repurchase_rate", id: "early_repurchase_rate" }],
      dimensions: [{ model: "Sales::RepurchaseIntervalFacts", field: "order_date", operator: "date_trunc_day", id: "date" }],
    )

    assert_equal [], result
  end

  def run_query(spec)
    DataModel::Query.new(@account, SuperproWarehouse, spec).run
  end
end
