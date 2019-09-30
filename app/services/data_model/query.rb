# frozen_string_literal: true

require "json-schema"

module DataModel
  class Query
    include SemanticLogger::Loggable

    SCHEMA_PATH = Rails.root.join("app", "services", "data_model", "query_schema.json").to_s

    def self.query_schema
      # Hot reload the schema file in development
      if Rails.env.development?
        File.read(SCHEMA_PATH)
      else
        @schema ||= File.read(SCHEMA_PATH)
      end
    end

    attr_reader :account, :warehouse, :specification

    def initialize(account, warehouse, specification)
      @account = account
      @warehouse = warehouse
      @specification = specification
    end

    def validate!
      JSON::Validator.validate!(self.class.query_schema, @specification)
      if @specification[:measures].empty? && @specification[:dimensions].empty?
        raise "Nothing to query given"
      end

      @specification[:measures].each do |measure|
      end
      true
    end

    def introspection
      @introspection ||= DataModel::QueryIntrospection.new(@account, @warehouse, @specification)
    end

    def run
      compiler = QueryCompiler.new(@account, @warehouse, @specification)
      raw_results = execute(compiler.sql)
      process(raw_results, compiler)
    end

    private

    def process(results, compiler)
      introspection = self.introspection

      results.map do |result|
        result.each_with_object({}) do |(key, value), return_result|
          id_key = compiler.ids_by_alias.fetch(key)
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
