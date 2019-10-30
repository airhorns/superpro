# frozen_string_literal: true

task :scratch => :environment do
  query = {
    measures: [{ model: "Sales::OrderFacts", field: "total_price", operator: "sum", id: "total_price" }, { model: "Sales::OrderFacts", field: "total_weight", operator: "sum", id: "total_weight" }],
    dimensions: [{ model: "Sales::OrderFacts", field: "cancelled", id: "cancelled" }],
  }

  compiler = DataModel::QueryCompiler.new(Account.first, SuperproWarehouse, query)
  arel = compiler.arel
  byebug
  true
end
