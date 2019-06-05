class Types::CurrencyType < Types::BaseObject
  field :name, String, null: false
  field :iso_code, String, null: false
  field :symbol, String, null: false
  field :symbol_first, Boolean, null: false
  field :thousands_separator, String, null: false
  field :decimal_mark, String, null: false
end
