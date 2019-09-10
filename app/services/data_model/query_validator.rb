# frozen_string_literal: true

require "json-schema"

module DataModel::QueryValidator
  SCHEMA_PATH = Rails.root.join("app", "services", "data_model", "query_schema.json").to_s

  def self.validate!(query_specification)
    JSON::Validator.validate!(self.query_schema, query_specification)
    if query_specification[:measures].empty? && query_specification[:dimensions].empty?
      raise "Nothing to query given"
    end
    true
  end

  def self.query_schema
    # Hot reload the schema file in development
    if Rails.env.development?
      File.read(SCHEMA_PATH)
    else
      @schema ||= File.read(SCHEMA_PATH)
    end
  end
end
