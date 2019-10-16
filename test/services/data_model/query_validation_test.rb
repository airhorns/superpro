# frozen_string_literal: true

require "test_helper"

class DataModel::QueryValidationTest < ActiveSupport::TestCase
  test "it raises validation errors if there's an invalid query passed" do
    assert_raises do
      validate(
        measures: [],
      )
    end

    assert_raises do
      validate(
        measures: [],
        dimensions: [],
      )
    end

    assert_raises do
      validate(
        measures: [{ model: "Sales::OrderFacts" }],
        dimensions: [],
      )
    end
  end

  test "it raises validation errors if there are duplicate ids passed" do
    assert_raises do
      validate(
        measures: [
          { model: "Sales::OrderFacts", field: "total_price", id: "one" },
          { model: "Sales::OrderFacts", field: "total_price", id: "one" }
        ],
        dimensions: [],
      )
    end
  end

  def validate(spec)
    DataModel::Query.new(stub(id: 10), SuperproDataWarehouse, spec).validate!
  end
end
