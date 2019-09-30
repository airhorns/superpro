# frozen_string_literal: true

# == Schema Information
#
# Table name: facebook_ad_accounts
#
#  id            :bigint(8)        not null, primary key
#  access_token  :string           not null
#  configured    :boolean          default(FALSE), not null
#  expires_at    :datetime
#  grantor_name  :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint(8)        not null
#  creator_id    :bigint(8)        not null
#  fb_account_id :string
#  grantor_id    :string           not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#


require "test_helper"

class FacebookAdAccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
