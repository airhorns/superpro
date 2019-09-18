# frozen_string_literal: true

require "active_model"

# We use ActiveModel::Errors as result objects, and it's much easier to access the object the errors are on by passing around just the errors value.
module ActiveModel
  class Errors
    attr_reader :base
  end
end
