# frozen_string_literal: true

# == Schema Information
#
# Table name: singer_global_sync_states
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  state      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "test_helper"

class SingerGlobalSyncStateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
