# == Schema Information
#
# Table name: budget_lines
#
#  id              :bigint(8)        not null, primary key
#  amount_subunits :bigint(8)        not null
#  currency        :string           not null
#  description     :string           not null
#  discarded_at    :datetime
#  recurrence      :string           not null
#  section         :string           not null
#  sort_order      :integer          default(1), not null
#  variable        :boolean          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint(8)        not null
#  budget_id       :bigint(8)        not null
#  creator_id      :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (budget_id => budgets.id)
#  fk_rails_...  (creator_id => users.id)
#

class BudgetLine < ApplicationRecord
  include AccountScoped
  include MutationClientId
  include Discard::Model

  belongs_to :budget, optional: false, inverse_of: :budget_lines
  belongs_to :creator, class_name: "User", inverse_of: :created_budget_lines

  monetize :amount_subunits, as: "amount", with_model_currency: :currency

  validates :description, presence: true
  validates :variable, inclusion: { in: [true, false] }
  validates :recurrence, presence: true, rrule: true
end
