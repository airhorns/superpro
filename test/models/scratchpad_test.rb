# == Schema Information
#
# Table name: scratchpads
#
#  id                      :bigint(8)        not null, primary key
#  access_mode             :string           not null
#  closed_todo_count       :integer          default(0), not null
#  closest_future_deadline :datetime
#  discarded_at            :datetime
#  document                :json             not null
#  name                    :string           not null
#  open_todo_count         :integer          default(0), not null
#  total_todo_count        :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint(8)        not null
#  creator_id              :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

require "test_helper"

class ScratchpadTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
