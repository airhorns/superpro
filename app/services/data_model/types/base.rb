# frozen_string_literal: true

class DataModel::Types::Base
  def self.datelike?
    false
  end

  def self.numberlike?
    false
  end

  def self.process(value)
    value
  end

  def self.default_operator
    :sum
  end
end
