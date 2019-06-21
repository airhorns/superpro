# == Schema Information
#
# Table name: budget_lines
#
#  id                              :bigint(8)        not null, primary key
#  description                     :string           not null
#  section                         :string           not null
#  sort_order                      :integer          default(1), not null
#  value_type                      :string           not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  account_id                      :bigint(8)        not null
#  budget_id                       :bigint(8)        not null
#  creator_id                      :bigint(8)        not null
#  fixed_budget_line_descriptor_id :bigint(8)
#  series_id                       :bigint(8)        not null
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

  belongs_to :budget, optional: false, inverse_of: :budget_lines
  belongs_to :creator, class_name: "User", inverse_of: :created_budget_lines
  belongs_to :series, optional: false
  belongs_to :fixed_budget_line_descriptor, optional: true, validate: true

  enum value_type: { fixed: "datetime", series: "series" }, _prefix: true
  validates :value_type, inclusion: { in: ["fixed", "series"] }

  validate :descriptor_present_if_fixed_type?

  private

  def descriptor_present_if_fixed_type?
    if value_type_fixed?
      errors.add(:fixed_budget_line_descriptor, "must be present") if fixed_budget_line_descriptor.blank?
    end
  end
end
