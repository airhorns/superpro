# frozen_string_literal: true

class Types::Warehouse::WarehouseDataTypeEnum < Types::BaseEnum
  value "Boolean", value: DataModel::Types::Boolean
  value "Currency", value: DataModel::Types::Currency
  value "DateTime", value: DataModel::Types::DateTime
  value "Duration", value: DataModel::Types::Duration
  value "Number", value: DataModel::Types::Number
  value "Percentage", value: DataModel::Types::Percentage
  value "String", value: DataModel::Types::String
  value "Weight", value: DataModel::Types::Weight
end
