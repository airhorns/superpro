# frozen_string_literal: true

# == Schema Information
#
# Table name: shopify_shops
#
#  id                  :bigint           not null, primary key
#  access_token        :string
#  api_key             :string
#  name                :string           not null
#  password            :string
#  script_tag_setup_at :datetime
#  shopify_domain      :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  creator_id          :bigint           not null
#  shop_id             :bigint           not null
#
# Indexes
#
#  index_shopify_shops_on_account_id_and_shopify_domain  (account_id,shopify_domain) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

class ShopifyShop < ApplicationRecord
  include AccountScoped
  belongs_to :creator, class_name: "User", optional: false
  has_one :connection, as: :integration, dependent: :destroy
end
