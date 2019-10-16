# frozen_string_literal: true

require "test_helper"

class DataModel::OutputIntrospectionTest < ActiveSupport::TestCase
  setup do
    @account = stub(id: 10)
  end

  test "it introspects queries" do
    query = query_for_spec(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "average", id: "total_weight" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled_status" }],
    )

    introspection = DataModel::OutputIntrospection.new(query)
    assert_matches_snapshot JSON.pretty_generate(introspection.measures)
    assert_matches_snapshot JSON.pretty_generate(introspection.dimensions)
  end

  test "it reports the output type of operators that change the type" do
    query = query_for_spec(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [{ model: "Sales::OrderFacts", field: "created_at", id: "created_at", operator: "date_part_day_of_week" }],
    )

    introspection = DataModel::OutputIntrospection.new(query)
    assert_equal DataModel::Types::String, introspection.dimensions.detect { |field| field[:id] == "created_at" }[:data_type]
  end

  test "it reports the output type of pivoted columns" do
    query = query_for_spec(
      measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }],
      dimensions: [
        { model: "Sales::OrderFacts", field: "created_at", id: "created_at", operator: "date_part_day_of_week" },
        { model: "Sales::OrderFacts", field: "new_vs_returning", id: "new_vs_returning" },
      ],
    )

    pivot = pivot_for_spec(query,
                           pivot_field_ids: ["new_vs_returning"],
                           measure_ids: ["total_price"])

    introspection = DataModel::OutputIntrospection.new(query, pivot)

    assert_nil introspection.measures.detect { |field| field[:id] == "total_price" }
    assert_matches_snapshot JSON.pretty_generate(introspection.pivoted_measures.detect { |field| field[:id] == "total_price" })
  end

  private

  def query_for_spec(spec)
    DataModel::Query.new(@account, SuperproWarehouse, spec)
  end

  def pivot_for_spec(query, spec)
    pivot = DataModel::Pivot.new(@account, SuperproWarehouse, query, spec)
    pivot.run([])
    pivot
  end
end
