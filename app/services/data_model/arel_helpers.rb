# frozen_string_literal: true
module DataModel
  module ArelHelpers
    def nullif(expression, condition)
      named_function("nullif", [expression, condition])
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
  end
end
