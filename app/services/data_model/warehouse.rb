# frozen_string_literal: true

class DataModel::Warehouse
  class_attribute :fact_tables, instance_predicate: false, instance_accessor: false
  class_attribute :operators, instance_predicate: false, instance_accessor: false

  class << self
    def register_fact_table(fact_table)
      self.fact_tables[fact_table.name] = fact_table
    end

    def operator(key, **options, &block)
      operator = DataModel::Operator.new(key, **options, &block)
      self.operators[operator.key] = operator
    end

    def inherited(child_class)
      child_class.fact_tables = ActiveSupport::HashWithIndifferentAccess.new
      child_class.operators = ActiveSupport::HashWithIndifferentAccess.new
    end
  end
end
