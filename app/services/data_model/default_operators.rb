# frozen_string_literal: true

module DataModel
  module DefaultOperators
    extend ActiveSupport::Concern

    included do
      operator :count, &:count
      operator :count_distinct, &:count_distinct

      operator :sum, valid_on: :numberlike?, &:sum
      operator :max, valid_on: :numberlike?, &:maximum
      operator :min, valid_on: :numberlike?, &:minimum
      operator :average, valid_on: :numberlike?, &:average

      operator :date_trunc_day, valid_on: :datelike? do |node|
        Arel::Nodes::NamedFunction.new("date_trunc", [Arel.sql("'day'"), node])
      end
      operator :date_trunc_week, valid_on: :datelike? do |node|
        Arel::Nodes::NamedFunction.new("date_trunc", [Arel.sql("'week'"), node])
      end
      operator :date_trunc_month, valid_on: :datelike? do |node|
        Arel::Nodes::NamedFunction.new("date_trunc", [Arel.sql("'month'"), node])
      end
      operator :date_trunc_year, valid_on: :datelike? do |node|
        Arel::Nodes::NamedFunction.new("date_trunc", [Arel.sql("'year'"), node])
      end

      operator :date_part_hour, valid_on: :datelike?, output_type: Types::Number do |node|
        Arel::Nodes::NamedFunction.new("date_part", [Arel.sql("'hour'"), node])
      end
      operator :date_part_day_of_month, valid_on: :datelike?, output_type: Types::Number do |node|
        Arel::Nodes::NamedFunction.new("date_part", [Arel.sql("'day'"), node])
      end
      operator :date_part_day_of_week, valid_on: :datelike?, output_type: Types::Number do |node|
        Arel::Nodes::NamedFunction.new("date_part", [Arel.sql("'dow'"), node])
      end
      operator :date_part_week, valid_on: :datelike?, output_type: Types::Number do |node|
        Arel::Nodes::NamedFunction.new("date_part", [Arel.sql("'week'"), node])
      end
      operator :date_part_month, valid_on: :datelike?, output_type: Types::Number do |node|
        Arel::Nodes::NamedFunction.new("date_part", [Arel.sql("'month'"), node])
      end
      operator :date_part_year, valid_on: :datelike?, output_type: Types::Number do |node|
        Arel::Nodes::NamedFunction.new("date_part", [Arel.sql("'year'"), node])
      end
    end
  end
end
