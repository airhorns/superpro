# == Schema Information
#
# Table name: budget_lines
#
#  id               :bigint(8)        not null, primary key
#  amount_subunits  :bigint(8)        not null
#  currency         :string           not null
#  description      :string           not null
#  recurrence_rules :string           not null, is an Array
#  section          :string           not null
#  sort_order       :integer          default(1), not null
#  variable         :boolean          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint(8)        not null
#  budget_id        :bigint(8)        not null
#  creator_id       :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (budget_id => budgets.id)
#  fk_rails_...  (creator_id => users.id)
#

require 'test_helper'

class BudgetLineTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
