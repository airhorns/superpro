# frozen_string_literal: true

class SuperproWarehouse < DataModel::Warehouse
  register_fact_table Sales::OrderFacts
  register_fact_table Meta::ShopifyShopFacts
end
