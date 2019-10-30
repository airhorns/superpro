# frozen_string_literal: true
class CustomerSegment < ApplicationRecord
  include AccountScoped

  enum strategy: { infrastructure: "infrastructure", rules: "rules" }, _prefix: true
  validates :strategy, inclusion: { in: %w[infrastructure rules] }

  serialize :rules, Infrastructure::ArelJSONSerializer
end
