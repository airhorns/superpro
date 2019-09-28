# frozen_string_literal: true

class DataModel::Types::Percentage < DataModel::Types::Base
  def self.numberlike?
    true
  end
end
