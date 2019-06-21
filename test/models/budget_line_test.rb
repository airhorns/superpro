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

require "test_helper"

class BudgetLineTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
