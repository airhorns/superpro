# frozen_string_literal: true

class DataModel::Types::DateTime < DataModel::Types::Base
  def self.datelike?
    true
  end

  def self.default_operator
    :date_trunc_day
  end
end
