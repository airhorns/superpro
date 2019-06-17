# == Schema Information
#
# Table name: series
#
#  id         :bigint(8)        not null, primary key
#  currency   :string
#  x_type     :string           not null
#  y_type     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint(8)        not null
#  creator_id :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

class Series < ApplicationRecord
  include AccountScoped
  include MutationClientId

  enum x_type: { datetime: "datetime", number: "number", string: "string" }, _prefix: true
  enum y_type: { money: "money", number: "number", string: "string" }, _prefix: true

  belongs_to :creator, class_name: "User", inverse_of: :created_series
  has_many :cells, inverse_of: :series, autosave: true, dependent: :delete_all
end
