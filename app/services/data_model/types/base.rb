# frozen_string_literal: true

class DataModel::Types::Base
  def self.datelike?
    false
  end

  def self.to_enum
    name.underscore.split("/").last
  end

  def self.process(value)
    value
  end
end
