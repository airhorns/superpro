# frozen_string_literal: true

module DataModel
  class Query
    include SemanticLogger::Loggable

    attr_reader :account, :warehouse

    def initialize(account, warehouse)
      @account = account
      @warehouse = warehouse
    end

    def run(query_specification)
      compiler = QueryCompiler.new(@account, @warehouse, query_specification)
      introspection = QueryIntrospection.new(@account, @warehouse, query_specification)
      sql = compiler.sql

      raw_results = logger.measure_debug "executing query", query: sql do
        execute(sql)
      end

      process(raw_results, compiler, introspection)
    end

    private

    def process(results, compiler, introspection)
      results.map do |result|
        result.each_with_object({}) do |(key, value), return_result|
          id_key = compiler.ids_by_alias[key]
          data_type = introspection.type_for_field_id(id_key)
          return_result[id_key] = data_type.process(value)
        end
      end
    end

    def execute(sql)
      ActiveRecord::Base.connection.execute(sql).to_a
    end
  end
end
