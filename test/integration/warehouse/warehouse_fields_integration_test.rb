# frozen_string_literal: true
require "test_helper"

class WarehouseFieldsIntegrationTest < ActiveSupport::TestCase
  SuperproWarehouse.fact_tables.each do |name, fact_table|
    fact_table.measure_fields.each do |field_name, _field|
      test "measure field #{name}.#{field_name} can be selected from" do
        result = DataModel::Query.new(stub(id: 10), SuperproWarehouse).run(
          measures: [{ model: name, field: field_name, id: "test_measure" }],
          dimensions: [],
        )

        assert result
      end
    end

    fact_table.dimension_fields.each do |field_name, _field|
      test "dimension field #{name}.#{field_name} can be selected from" do
        result = DataModel::Query.new(stub(id: 10), SuperproWarehouse).run(
          measures: [{ model: name, field: "count", id: "count" }],
          dimensions: [{ model: name, field: field_name, id: "dimension" }],
        )

        assert result
      end
    end
  end
end
