# frozen_string_literal: true

class DataModel::Types::DateTime < DataModel::Types::Base
  def self.datelike?
    true
  end
end
