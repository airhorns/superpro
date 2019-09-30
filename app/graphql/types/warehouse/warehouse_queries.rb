# frozen_string_literal: true

module Types::Warehouse::WarehouseQueries
  extend ActiveSupport::Concern

  included do
    field :warehouse_query, Types::Warehouse::WarehouseQueryResultType, null: false do
      description "Execute a query against the Superpro data model"
      argument :query, Types::JSONScalar, required: true
    end

    field :warehouse_introspection, Types::Warehouse::WarehouseIntrospectionType, null: false do
      description "Get a datastructure describing all the available models and fields available in the Superpro data model"
    end
  end

  def warehouse_query(query:)
    query_specification = query.permit!.to_h
    query = DataModel::Query.new(context[:current_account], SuperproWarehouse, query_specification)
    query.validate!

    {
      records: query.run,
      query_introspection: query.introspection.as_json,
      errors: nil,
    }
  end

  def warehouse_introspection
    DataModel::WarehouseIntrospection.new(context[:current_account], SuperproWarehouse).as_json
  end
end
