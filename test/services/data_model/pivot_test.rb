# frozen_string_literal: true

require "test_helper"

class DataModel::PivotTest < ActiveSupport::TestCase
  setup do
    @account = stub(id: 10)
    @color_query = stub(all_field_ids: %i[date count color])
    @color_size_query = stub(all_field_ids: %i[date count color size])
  end

  test "it can pivot one measure by one column" do
    raw_results = [
      { date: 1, count: 1, color: "red" },
      { date: 1, count: 2, color: "green" },
      { date: 2, count: 3, color: "red" },
      { date: 2, count: 4, color: "green" },
      { date: 3, count: 6, color: "red" },
      { date: 4, count: 5, color: "green" },
    ]

    pivot = DataModel::Pivot.new(
      @account,
      SuperproWarehouse,
      @color_query,
      pivot_field_ids: [:color],
      measure_ids: [:count],
    )

    assert_equal [
      { date: 1, "count / red" => 1, "count / green" => 2 },
      { date: 2, "count / red" => 3, "count / green" => 4 },
      { date: 3, "count / red" => 6, "count / green" => nil },
      { date: 4, "count / red" => nil, "count / green" => 5 },
    ], pivot_with_nice_columns(raw_results, pivot)
  end

  test "it can pivot no rows" do
    pivoted = DataModel::Pivot.new(
      @account,
      SuperproWarehouse,
      @color_query,
      pivot_field_ids: [:color],
      measure_ids: [:count],
    ).run([])

    assert_equal [], pivoted
  end

  test "it can pivot one measure by multiple columns" do
    raw_results = [
      { date: 1, count: 1, color: "red", size: "large" },
      { date: 1, count: 2, color: "red", size: "small" },
      { date: 1, count: 3, color: "green", size: "large" },
      { date: 1, count: 4, color: "green", size: "small" },
      { date: 2, count: 5, color: "red", size: "large" },
      { date: 2, count: 6, color: "red", size: "small" },
      { date: 2, count: 7, color: "green", size: "large" },
      { date: 2, count: 8, color: "green", size: "small" },
      { date: 3, count: 9, color: "green", size: "small" },
      { date: 3, count: 10, color: "red", size: "large" },
    ]

    pivot = DataModel::Pivot.new(
      @account,
      SuperproWarehouse,
      @color_size_query,
      pivot_field_ids: %i[color size],
      measure_ids: [:count],
    )

    assert_equal [
      { date: 1, "count / red,small" => 2, "count / red,large" => 1, "count / green,small" => 4, "count / green,large" => 3 },
      { date: 2, "count / red,small" => 6, "count / red,large" => 5, "count / green,small" => 8, "count / green,large" => 7 },
      { date: 3, "count / red,small" => nil, "count / red,large" => 10, "count / green,small" => 9, "count / green,large" => nil },
    ], pivot_with_nice_columns(raw_results, pivot)
  end

  test "it can pivot one measure by one column with multiple group columns" do
    raw_results = [
      { date: 1, count: 1, color: "red", size: "large" },
      { date: 1, count: 2, color: "red", size: "small" },
      { date: 1, count: 3, color: "green", size: "large" },
      { date: 1, count: 4, color: "green", size: "small" },
      { date: 2, count: 5, color: "red", size: "large" },
      { date: 2, count: 6, color: "red", size: "small" },
      { date: 2, count: 7, color: "green", size: "large" },
      { date: 2, count: 8, color: "green", size: "small" },
      { date: 3, count: 9, color: "green", size: "small" },
      { date: 3, count: 10, color: "red", size: "large" },
    ]

    pivot = DataModel::Pivot.new(@account, SuperproWarehouse, @color_size_query,
                                 pivot_field_ids: [:color],
                                 measure_ids: [:count])

    assert_equal [
      { date: 1, size: "large", "count / red" => 1, "count / green" => 3 },
      { date: 1, size: "small", "count / red" => 2, "count / green" => 4 },
      { date: 2, size: "large", "count / red" => 5, "count / green" => 7 },
      { date: 2, size: "small", "count / red" => 6, "count / green" => 8 },
      { date: 3, size: "small", "count / red" => nil, "count / green" => 9 },
      { date: 3, size: "large", "count / red" => 10, "count / green" => nil },
    ], pivot_with_nice_columns(raw_results, pivot)
  end

  private

  def pivot_with_nice_columns(data, pivot)
    results = pivot.run(data)

    nice_column_names = pivot.generated_columns.each_with_object({}) do |column, agg|
      agg[column[:id]] = "#{column[:measure_column]} / #{column[:pivot_column_values].join(",")}"
    end

    results.each do |record|
      nice_column_names.each do |id, nice_name|
        record[nice_name] = record[id]
        record.delete(id)
      end
    end

    results
  end
end
