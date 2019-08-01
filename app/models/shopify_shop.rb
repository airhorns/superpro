# == Schema Information
#
# Table name: shopify_shops
#
#  id             :bigint(8)        not null, primary key
#  api_key        :string           not null
#  name           :string           not null
#  password       :string           not null
#  shopify_domain :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint(8)        not null
#  creator_id     :bigint(8)        not null
#  shop_id        :bigint(8)        not null
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
end