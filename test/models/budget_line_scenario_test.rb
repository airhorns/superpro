# == Schema Information
#
# Table name: budget_line_scenarios
#
#  id                              :bigint(8)        not null, primary key
#  amount_subunits                 :bigint(8)        not null
#  currency                        :string           not null
#  scenario                        :string           not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  account_id                      :bigint(8)        not null
#  fixed_budget_line_descriptor_id :bigint(8)        not null
#
# Indexes
#
#  idx_scenarios_to_fixed_descriptors  (account_id,fixed_budget_line_descriptor_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (fixed_budget_line_descriptor_id => fixed_budget_line_descriptors.id)
#

require "test_helper"

class BudgetLineScenarioTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
