# frozen_string_literal: true

# == Schema Information
#
# Table name: plaid_transactions
#
#  id                           :bigint(8)        not null, primary key
#  amount                       :string           not null
#  category                     :string           is an Array
#  date                         :date             not null
#  iso_currency_code            :string
#  name                         :string           not null
#  plaid_account_identifier     :string           not null
#  plaid_transaction_identifier :string           not null
#  transaction_type             :string           not null
#  unofficial_currency_code     :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  account_id                   :bigint(8)        not null
#  category_id                  :string
#  plaid_item_id                :bigint(8)        not null
#
# Indexes
#
#  index_plaid_transactions_on_plaid_transaction_identifier  (plaid_transaction_identifier) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (plaid_item_id => plaid_items.id)
#

require "test_helper"

class PlaidTransactionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
