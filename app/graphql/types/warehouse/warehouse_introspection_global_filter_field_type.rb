# frozen_string_literal: true

class Types::Warehouse::WarehouseIntrospectionGlobalFilterFieldType < Types::BaseObject
  field :filter_id, String, null: false
  field :field, String, null: false
end
