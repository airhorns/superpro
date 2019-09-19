# frozen_string_literal: true

module Types::Warehouse::WarehouseQueries
  extend ActiveSupport::Concern

  included do
    field :warehouse_query, Types::Warehouse::WarehouseQueryResultType, null: false do
      description "Execute a query against the Superpro data model"
      argument :query, Types::JSONScalar, required: true
    end
  end

  def warehouse_query(query:)
    query_specification = query.permit!.to_h
    DataModel::QueryValidator.validate!(query_specification)
    {
      records: DataModel::Query.new(context[:current_account], SuperproWarehouse).run(query_specification),
      query_introspection: DataModel::QueryIntrospection.new(context[:current_account], SuperproWarehouse, query_specification).as_json,
      errors: nil,
    }
  end
end
