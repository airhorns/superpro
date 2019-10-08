# frozen_string_literal: true

class Types::Warehouse::WarehouseOutputIntrospectionType < Types::BaseObject
  field :dimensions, [Types::Warehouse::WarehouseOutputIntrospectionDimensionType], null: false
  field :measures, [Types::Warehouse::WarehouseOutputIntrospectionMeasureType], null: false
  field :pivoted_measures, [Types::Warehouse::WarehouseOutputIntrospectionMeasureType], null: false
end
