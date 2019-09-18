# frozen_string_literal: true

class Types::MoneyType < Types::BaseObject
  field :fractional, Integer, null: false
  field :formatted, String, null: false
  field :currency, Types::CurrencyType, null: false

  def formatted
    object.format
  end
end
