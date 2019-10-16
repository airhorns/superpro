# frozen_string_literal: true

# == Schema Information
#
# Table name: singer_sync_states
#
#  id            :bigint           not null, primary key
#  state         :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  connection_id :bigint           not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (connection_id => connections.id)
#

require "test_helper"

class SingerSyncStateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
