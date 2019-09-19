# frozen_string_literal: true

class DataModel::DimensionTable
  class_attribute :table, instance_predicate: false, instance_accessor: false, default: []
  class_attribute :primary_key, instance_predicate: false, instance_accessor: false
  class_attribute :dimension_fields, instance_predicate: false, instance_accessor: false, default: []

  class << self
    def dimension(field, type)
      self.dimension_fields << DataModel::DimensionField.new(field, type)
    end

    def dimension_join(name)
    end
  end
end
