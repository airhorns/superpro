# frozen_string_literal: true
module DataModel
  module ArelHelpers
    def nullif(expression, condition)
      named_function("nullif", [expression, condition])
    end

    def concat(*expressions)
      named_function("concat", expressions)
    end

    def named_function(function_name, expressions)
      Arel::Nodes::NamedFunction.new(function_name, expressions)
    end

    def sql_string(node)
      ActiveRecord::Base.connection.visitor.compile(node)
    end

    def cast(node, type)
      case type
      when :numeric
        node * Arel.sql("1.0")
      end
    end

    # Use an anonymouse ActiveRecord::Base subclass that knows which table it's pointed at to boot up an Arel::Table
    # for the table in question. This seems weird but works well as it's only using public Rails APIs, and it sets
    # up all the right casting and schema awareness that Rails usually uses for to_sqling queries.
    def table_node_for_table(table)
      klass = Class.new(ApplicationRecord) do
        self.table_name = table
      end
      klass.arel_table
    end
  end
end
