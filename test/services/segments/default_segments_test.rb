# frozen_string_literal: true

require "test_helper"

class Segments::DefaultSegmentsTest < ActiveSupport::TestCase
  Segments::DefaultSegments::DEFAULT_SEGMENTS.select { |segment| segment.rules_strategy? }.each do |segment|
    test "segment #{segment.name} has valid rules" do
      arel = segment.rules
      table_node = Sales::CustomersDimension.table_node
      manager = Arel::SelectManager.new
      manager.project(table_node[:id])

      assert_equal [],
    end
  end
end
