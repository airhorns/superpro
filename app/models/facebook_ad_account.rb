# frozen_string_literal: true

# == Schema Information
#
# Table name: facebook_ad_accounts
#
#  id              :bigint           not null, primary key
#  access_token    :string           not null
#  configured      :boolean          default(FALSE), not null
#  expires_at      :datetime
#  fb_account_name :string
#  grantor_name    :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  creator_id      :bigint           not null
#  fb_account_id   :string
#  grantor_id      :string           not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

class FacebookAdAccount < ApplicationRecord
  include AccountScoped
  belongs_to :creator, class_name: "User", optional: false
  has_one :connection, as: :integration, dependent: :destroy

  def session
    FacebookAds::Session.new(
      access_token: self.access_token,
      app_secret: Rails.configuration.facebook[:app_secret],
    )
  end

  def with_session_active
    original_session = FacebookAds::Session.current_session
    FacebookAds::Session.current_session = session
    FacebookAds::Session.default_session = session
    yield
  ensure
    FacebookAds::Session.current_session = original_session
    FacebookAds::Session.default_session = original_session
  end
end
