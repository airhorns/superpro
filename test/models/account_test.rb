# == Schema Information
#
# Table name: accounts
#
#  id           :bigint(8)        not null, primary key
#  discarded_at :datetime
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  creator_id   :bigint(8)        not null
#
# Indexes
#
#  index_accounts_on_discarded_at  (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
