# frozen_string_literal: true

class DataModel::Types::Weight < DataModel::Types::Base
  def self.process(value)
    value.to_i
  end
end
