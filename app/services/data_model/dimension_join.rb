# frozen_string_literal: true

module DataModel
  class DimensionJoin
    attr_reader :name, :model, :key_in_fact_table

    def initialize(name, dimension_model, fact_key: nil)
      @name = name
      @model = dimension_model
      @key_in_fact_table = fact_key || "#{name}_id"
    end
  end
end
