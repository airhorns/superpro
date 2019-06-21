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

require "test_helper"

class FixedBudgetLineDescriptorTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
