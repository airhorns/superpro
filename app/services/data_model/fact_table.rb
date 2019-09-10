# frozen_string_literal: true

class DataModel::FactTable
  class_attribute :table, instance_predicate: false, instance_accessor: false
  class_attribute :measure_fields, instance_predicate: false, instance_accessor: false, default: ActiveSupport::HashWithIndifferentAccess.new
  class_attribute :dimension_fields, instance_predicate: false, instance_accessor: false, default: ActiveSupport::HashWithIndifferentAccess.new
  class_attribute :all_fields, instance_predicate: false, instance_accessor: false, default: ActiveSupport::HashWithIndifferentAccess.new

  class << self
    def measure(name, type, **options)
      field = DataModel::MeasureField.new(name, type, **options)
      self.measure_fields[name] = field
      self.all_fields[name] = field
    end

    def dimension(name, type, **options)
      field = DataModel::DimensionField.new(name, type, **options)
      self.dimension_fields[name] = field
      self.all_fields[name] = field
    end

    def dimension_join(name, dimension)
    end

    def inherited(child_class)
      child_class.measure :count, DataModel::Types::Number, sql: Arel.sql("1").count, allow_operators: false
    end
  end
end
