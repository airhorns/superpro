# frozen_string_literal: true

class DataModel::Warehouse
  class_attribute :fact_tables, instance_predicate: false, instance_accessor: false, default: {}
  class_attribute :operators, instance_predicate: false, instance_accessor: false, default: {}

  class << self
    def register_fact_table(fact_table)
      self.fact_tables[fact_table.name] = fact_table
    end

    def operator(key, **options, &block)
      operator = DataModel::Operator.new(key, **options, &block)
      self.operators[operator.key] = operator
    end
  end
end
