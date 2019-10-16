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

    attr_reader :account, :warehouse, :specification, :measures, :dimensions

    def initialize(account, warehouse, specification)
      @account = account
      @warehouse = warehouse
      @specification = specification

      @measures = @specification.fetch(:measures, [])
      @dimensions = @specification.fetch(:dimensions, [])
      @specs_by_id = (@measures + @dimensions).index_by { |spec| spec[:id].to_s }
    end

    def validate!
      JSON::Validator.validate!(self.class.query_schema, @specification)
      if @measures.empty? && @dimensions.empty?
        raise "Nothing to query given"
      end

      if @specs_by_id.size < (@measures.size + @dimensions.size)
        id_counts = (@measures.map { |spec| spec[:id] } + @dimensions.map { |spec| spec[:id] }).each_with_object(Hash.new(0)) do |id, totals|
          totals[id] += 1
        end
        duplicate_ids = id_counts.select { |_id, count| count > 1 }.keys

        raise "Invalid query, duplicate IDs detected. IDs: #{duplicate_ids.join(",")}"
      end
      true
    end

    def run
      @results ||= begin
        compiler = QueryCompiler.new(@account, @warehouse, @specification)
        raw_results = execute(compiler.sql)
        process(raw_results, compiler)
      end
    end

    def all_field_ids
      @specs_by_id.keys
    end

    def type_for_field_id(id)
      type_for_field_spec(@specs_by_id.fetch(id.to_s))
    end

    def type_for_field_spec(spec)
      model_field_for_field_spec(spec).data_type
    end

    def model_field_for_field_spec(spec)
      model = @warehouse.fact_tables[spec[:model]] || @warehouse.dimension_tables[spec[:model]]
      if model.nil?
        raise "Unknown model field in spec #{spec}"
      end

      model.all_fields.fetch(spec[:field].to_sym)
    end

    private

    def process(results, compiler)
      results.map do |result|
        result.each_with_object({}) do |(key, value), return_result|
          id_key = compiler.ids_by_alias.fetch(key)
          data_type = type_for_field_id(id_key)
          return_result[id_key] = data_type.process(value)
        end
      end
    end

    def execute(sql)
      ActiveRecord::Base.connection.execute(sql).to_a
    end
  end
end
