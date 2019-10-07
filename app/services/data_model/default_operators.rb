# frozen_string_literal: true

module DataModel
  module DefaultOperators
    extend ActiveSupport::Concern

    included do
      extend DataModel::ArelHelpers

      operator :count, &:count
      operator :count_distinct, &:count_distinct

      operator :sum, valid_on: :numberlike?, &:sum
      operator :max, valid_on: :numberlike?, &:maximum
      operator :min, valid_on: :numberlike?, &:minimum
      operator :average, valid_on: :numberlike?, &:average

      operator :p80, valid_on: :numberlike? do |node|
        Arel.sql("percentile_cont(0.8) within group ( order by #{sql_string(node)} )")
      end
      operator :p90, valid_on: :numberlike? do |node|
        Arel.sql("percentile_cont(0.9) within group ( order by #{sql_string(node)} )")
      end
      operator :p95, valid_on: :numberlike? do |node|
        Arel.sql("percentile_cont(0.95) within group ( order by #{sql_string(node)} )")
      end

      operator :date_trunc_day, valid_on: :datelike? do |node|
        named_function("date_trunc", [Arel.sql("'day'"), node])
      end
      operator :date_trunc_week, valid_on: :datelike? do |node|
        named_function("date_trunc", [Arel.sql("'week'"), node])
      end
      operator :date_trunc_month, valid_on: :datelike? do |node|
        named_function("date_trunc", [Arel.sql("'month'"), node])
      end
      operator :date_trunc_year, valid_on: :datelike? do |node|
        named_function("date_trunc", [Arel.sql("'year'"), node])
      end

      operator :date_part_hour, valid_on: :datelike?, output_type: Types::String do |node|
        named_function("date_part", [Arel.sql("'hour'"), node])
      end
      operator :date_part_day_of_month, valid_on: :datelike?, output_type: Types::String do |node|
        named_function("date_part", [Arel.sql("'day'"), node])
      end
      operator :date_part_day_of_week, valid_on: :datelike?, output_type: Types::String do |node|
        named_function("date_part", [Arel.sql("'dow'"), node])
      end
      operator :date_part_week, valid_on: :datelike?, output_type: Types::Number do |node|
        named_function("date_part", [Arel.sql("'week'"), node])
      end
      operator :date_part_month, valid_on: :datelike?, output_type: Types::Number do |node|
        named_function("date_part", [Arel.sql("'month'"), node])
      end
      operator :date_part_year, valid_on: :datelike?, output_type: Types::Number do |node|
        named_function("date_part", [Arel.sql("'year'"), node])
      end
    end
  end
end
