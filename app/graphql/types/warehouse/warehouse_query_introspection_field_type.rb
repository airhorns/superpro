# frozen_string_literal: true

class Types::Warehouse::WarehouseQueryIntrospectionFieldType < Types::BaseObject
  field :id, String, null: false
  field :type, String, null: false
  field :label, String, null: false
  field :sortable, Boolean, null: false
end
