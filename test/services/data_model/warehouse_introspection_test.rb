# frozen_string_literal: true
require "test_helper"

class DataModel::WarehouseIntrospectionTest < ActiveSupport::TestCase
  setup do
    @account = stub(id: 10)
    @introspection = DataModel::WarehouseIntrospection.new(@account, SuperproWarehouse)
  end

  test "it introspects the superpro warehouse" do
    assert @introspection.fact_tables.any? { |table_blob| table_blob[:name] == "Sales::OrderFacts" }
  end
end
