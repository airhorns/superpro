# frozen_string_literal: true

module Types::Warehouse::WarehouseQueries
  extend ActiveSupport::Concern

  included do
    field :warehouse_query, Types::Warehouse::WarehouseQueryResultType, null: false do
      description "Execute a query against the Superpro data model"
      argument :query, Types::JSONScalar, required: true
      argument :pivot, Types::JSONScalar, required: false
    end

    field :warehouse_introspection, Types::Warehouse::WarehouseIntrospectionType, null: false do
      description "Get a datastructure describing all the available models and fields available in the Superpro data model"
    end
  end

  def warehouse_query(query:, pivot: nil)
    query = DataModel::Query.new(context[:current_account], SuperproWarehouse, query.permit!.to_h)
    query.validate!
    results = query.run

    pivoter = nil
    if pivot
      pivoter = DataModel::Pivot.new(context[:current_account], SuperproWarehouse, query, pivot.permit!.to_h)
      results = pivoter.run(results)
    end

    introspection = DataModel::OutputIntrospection.new(query, pivoter)

    {
      records: results,
      output_introspection: introspection,
      errors: nil,
    }
  end

  def warehouse_introspection
    DataModel::WarehouseIntrospection.new(context[:current_account], SuperproWarehouse).as_json
  end
end
