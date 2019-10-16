# frozen_string_literal: true

# == Schema Information
#
# Table name: plaid_items
#
#  id                      :bigint           not null, primary key
#  access_token            :string           not null
#  initial_update_complete :boolean          default(FALSE), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  creator_id              :bigint           not null
#  item_id                 :bigint           not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

require "test_helper"

class PlaidItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
