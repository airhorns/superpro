# == Schema Information
#
# Table name: process_execution_involved_users
#
#  id                   :bigint(8)        not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint(8)        not null
#  process_execution_id :bigint(8)        not null
#  user_id              :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (process_execution_id => process_executions.id)
#  fk_rails_...  (user_id => users.id)
#

require "test_helper"

class ProcessExecutionInvolvedUserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
