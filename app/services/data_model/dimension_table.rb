# frozen_string_literal: true

class DataModel::DimensionTable
  class_attribute :table, instance_predicate: false, instance_accessor: false
  class_attribute :primary_key, instance_predicate: false, instance_accessor: false
  class_attribute :dimension_fields, instance_predicate: false, instance_accessor: false

  class << self
    def table_node
      @table_node ||= Arel::Table.new(self.table)
    end

    def dimension(name, type, **options, &block)
      self.dimension_fields[name] = DataModel::DimensionField.new(name, type, **options, &block)
    end

    def inherited(child_class)
      child_class.dimension_fields = ActiveSupport::HashWithIndifferentAccess.new
    end
  end
end
