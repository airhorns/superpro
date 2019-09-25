# frozen_string_literal: true

class SuperproWarehouse < DataModel::Warehouse
  include DataModel::DefaultOperators

  register_fact_table Sales::OrderFacts
  register_fact_table Sales::CustomerParetoFacts
  register_fact_table Sales::RepurchaseCohortFacts
  register_fact_table Sales::RepurchaseIntervalFacts

  register_fact_table Traffic::SessionFacts
  register_fact_table Traffic::PageViewFacts

  register_fact_table Meta::ShopifyShopFacts
end
