# frozen_string_literal: true

# == Schema Information
#
# Table name: account_user_permissions
#
#  id         :bigint(8)        not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint(8)        not null
#  user_id    :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#

class AccountUserPermission < ApplicationRecord
  belongs_to :account
  belongs_to :user
end
