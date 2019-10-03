# frozen_string_literal: true

module DataModel
  class FactTable
    extend DataModel::ArelHelpers

    class_attribute :table, instance_predicate: false, instance_accessor: false
    class_attribute :measure_fields, instance_predicate: false, instance_accessor: false
    class_attribute :dimension_fields, instance_predicate: false, instance_accessor: false
    class_attribute :all_fields, instance_predicate: false, instance_accessor: false

    class << self
      def table_node
        @table_node ||= Arel::Table.new(self.table)
      end

      def measure(name, type, **options, &block)
        field = MeasureField.new(name, type, **options, &block)
        self.measure_fields[name] = field
        self.all_fields[name] = field
      end

      def dimension(name, type, **options, &block)
        field = DimensionField.new(name, type, **options, &block)
        self.dimension_fields[name] = field
        self.all_fields[name] = field
      end

      def dimension_join(name, dimension, **options)
        join = DimensionJoin.new(name, dimension, **options)
        prefix = name.to_s.underscore
        nice_prefix = name.to_s.capitalize
        dimension.dimension_fields.each do |_key, dimension_field|
          self.dimension(
            "#{prefix}_#{dimension_field.field_name}",
            dimension_field.data_type,
            column: dimension_field.column_name,
            sql: dimension_field.custom_sql_node,
            label: "#{nice_prefix} #{dimension_field.field_label}",
            join: join,
          )
        end
      end

      def inherited(child_class)
        child_class.measure_fields = ActiveSupport::HashWithIndifferentAccess.new
        child_class.dimension_fields = ActiveSupport::HashWithIndifferentAccess.new
        child_class.all_fields = ActiveSupport::HashWithIndifferentAccess.new
        child_class.measure :count, DataModel::Types::Number, sql: Arel.sql("1").count, allow_operators: false
      end
    end
  end
end
