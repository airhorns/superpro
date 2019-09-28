# frozen_string_literal: true

class DataModel::Types::Duration < DataModel::Types::Base
  def self.numberlike?
    true
  end
end
