# == Schema Information
#
# Table name: accounts
#
#  id           :bigint(8)        not null, primary key
#  discarded_at :datetime
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  creator_id   :bigint(8)        not null
#
# Indexes
#
#  index_accounts_on_discarded_at  (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#
class Account < ApplicationRecord
  include Discard::Model
  include MutationClientId

  validates :name, presence: true
  validates :creator, presence: true

  has_many :account_user_permissions, inverse_of: :account, dependent: :destroy
  has_many :permissioned_users, through: :account_user_permissions, source: :user
  has_many :budgets, inverse_of: :account, dependent: :destroy
  has_many :process_templates, inverse_of: :account, dependent: :destroy
  has_many :process_executions, inverse_of: :account, dependent: :destroy
  has_many :scratchpads, inverse_of: :account, dependent: :destroy do
    def for_user(user)
      where("access_mode = 'public' OR (access_mode = 'private' AND scratchpads.creator_id = ?)", user.id)
    end
  end

  has_many :todo_feed_items, inverse_of: :account do # rubocop:disable Rails/HasManyOrHasOneDependent
    def for_user(user)
      where("access_mode = 'public' OR (access_mode = 'private' AND creator_id = ?)", user.id)
    end
  end

  has_many :connections, inverse_of: :account, dependent: :destroy
  has_many :plaid_items, inverse_of: :account, dependent: :destroy
  has_many :plaid_item_accounts, inverse_of: :account, dependent: :destroy
  has_many :plaid_transactions, inverse_of: :account, dependent: :destroy
  has_many :shopify_shops, inverse_of: :account, dependent: :destroy

  belongs_to :creator, class_name: "User", inverse_of: :created_accounts

  def flipper_id
    @flipper_id ||= "account-#{id}"
  end
end
