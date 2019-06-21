# == Schema Information
#
# Table name: fixed_budget_line_descriptors
#
#  id               :bigint(8)        not null, primary key
#  occurs_at        :datetime         not null
#  recurrence_rules :string           is an Array
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint(8)        not null
#

class FixedBudgetLineDescriptor < ApplicationRecord
  include AccountScoped

  has_many :budget_line_scenarios, autosave: true, validate: true, dependent: :destroy, inverse_of: :fixed_budget_line_descriptor
  has_one :budget_line, dependent: :nullify

  validates :recurrence_rules, rrule_list: true
end
