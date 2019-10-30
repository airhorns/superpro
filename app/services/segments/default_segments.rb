# frozen_string_literal: true
module Segments
  module DefaultSegments
    extend DataModel::ArelHelpers

    customers_table = Sales::CustomersDimension.table_node

    DEFAULT_SEGMENTS = [
      CustomerSegment.build(
        name: "Loyals",
        description: "All customers with 3 or more purchases",
        strategy: "rules",
        rules: table_node[:total_order_count] >= 3,
      ),
      CustomerSegment.build(
        name: "Repeats",
        description: "All customers who've purchased more than once",
        strategy: "rules",
        rules: table_node[:total_order_count] > 1,
      ),
      CustomerSegment.build(
        name: "One timers",
        description: "All customers who've purchased at least once successfully",
        strategy: "rules",
        rules: table_node[:total_successful_order_count] > 0,
      ),
    ]
  end
end
