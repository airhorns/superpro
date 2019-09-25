# frozen_string_literal: true

class DataModel::Types::Number < DataModel::Types::Base
  def self.numberlike?
    true
  end
end
