# frozen_string_literal: true

# == Schema Information
#
# Table name: plaid_item_accounts
#
#  id                       :bigint           not null, primary key
#  name                     :string           not null
#  plaid_account_identifier :string           not null
#  subtype                  :string           not null
#  type                     :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  plaid_item_id            :bigint           not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (plaid_item_id => plaid_items.id)
#

require "test_helper"

class PlaidItemAccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
