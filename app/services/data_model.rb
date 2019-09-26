# frozen_string_literal: true

module DataModel
  def self.sql_string(node)
    ActiveRecord::Base.connection.visitor.compile(node)
  end
end
