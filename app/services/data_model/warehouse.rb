# frozen_string_literal: true

class DataModel::Warehouse
  class_attribute :fact_tables, instance_predicate: false, instance_accessor: false, default: {}

  class << self
    def register_fact_table(fact_table)
      self.fact_tables[fact_table.name] = fact_table
    end
  end
end
