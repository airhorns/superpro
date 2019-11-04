# frozen_string_literal: true

module DataModel
  class DimensionTable
    extend DataModel::ArelHelpers

    class_attribute :table, instance_predicate: false, instance_accessor: false
    class_attribute :primary_key, instance_predicate: false, instance_accessor: false
    class_attribute :dimension_fields, instance_predicate: false, instance_accessor: false
    class_attribute :measure_fields, instance_predicate: false, instance_accessor: false

    class << self
      def table_node
        @table_node ||= table_node_for_table(self.table)
      end

      def dimension(name, type, measureable: false, **options, &block)
        self.dimension_fields[name] = DimensionField.new(name, type, **options, &block)
        if measureable
          self.measure(name, type, **options)
        end
      end

      def measure(name, type, **options, &block)
        self.measure_fields[name] = MeasureField.new(name, type, **options, &block)
      end

      def inherited(child_class)
        child_class.dimension_fields = ActiveSupport::HashWithIndifferentAccess.new
        child_class.measure_fields = ActiveSupport::HashWithIndifferentAccess.new
      end
    end
  end
end
