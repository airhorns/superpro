# == Schema Information
#
# Table name: budget_line_scenarios
#
#  id              :bigint(8)        not null, primary key
#  amount_subunits :bigint(8)        not null
#  currency        :string           not null
#  scenario        :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint(8)        not null
#  budget_line_id  :bigint(8)        not null
#  series_id       :bigint(8)        not null
#
# Indexes
#
#  index_budget_line_scenarios_on_account_id_and_budget_line_id  (account_id,budget_line_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (budget_line_id => budget_lines.id)
#

require "test_helper"

class BudgetLineScenarioTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
