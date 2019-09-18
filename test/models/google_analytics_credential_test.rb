# frozen_string_literal: true

# == Schema Information
#
# Table name: google_analytics_credentials
#
#  id              :bigint(8)        not null, primary key
#  configured      :boolean          default(FALSE), not null
#  expires_at      :datetime
#  ga_account_name :string
#  grantor_email   :string           not null
#  grantor_name    :string           not null
#  property_name   :string
#  refresh_token   :string           not null
#  token           :string           not null
#  view_name       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint(8)        not null
#  creator_id      :bigint(8)        not null
#  ga_account_id   :bigint(8)
#  property_id     :bigint(8)
#  view_id         :bigint(8)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

require "test_helper"

class GoogleAnalyticsCredentialTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
