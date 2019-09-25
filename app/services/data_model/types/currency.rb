# frozen_string_literal: true

class DataModel::Types::Currency < DataModel::Types::Base
  def self.numberlike?
    true
  end
end
