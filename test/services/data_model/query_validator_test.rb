# frozen_string_literal: true

require "test_helper"

class DataModel::QueryValidatorTest < ActiveSupport::TestCase
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

  def validate(spec)
    DataModel::QueryValidator.validate!(spec)
  end
end
