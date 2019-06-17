# == Schema Information
#
# Table name: budget_lines
#
#  id               :bigint(8)        not null, primary key
#  description      :string           not null
#  occurs_at        :datetime         not null
#  recurrence_rules :string           is an Array
#  section          :string           not null
#  sort_order       :integer          default(1), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint(8)        not null
#  budget_id        :bigint(8)        not null
#  creator_id       :bigint(8)        not null
#  series_id        :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (budget_id => budgets.id)
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (series_id => series.id)
#

class BudgetLine < ApplicationRecord
  include AccountScoped
  include MutationClientId

  validates :description, presence: true
  validates :recurrence_rules, rrule_list: true

  belongs_to :budget, optional: false, inverse_of: :budget_lines
  belongs_to :creator, class_name: "User", inverse_of: :created_budget_lines
  belongs_to :series

  has_many :budget_line_scenarios, autosave: true, validate: true, dependent: :destroy, inverse_of: :budget_line
end
