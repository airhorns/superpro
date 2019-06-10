# == Schema Information
#
# Table name: budgets
#
#  id           :bigint(8)        not null, primary key
#  discarded_at :datetime
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint(8)        not null
#  creator_id   :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

class Budget < ApplicationRecord
  include Discard::Model
  include AccountScoped
  include MutationClientId

  validates :name, presence: true
  validates :creator, presence: true

  has_many :budget_lines, inverse_of: :budget, dependent: :destroy, autosave: true, validate: true
  belongs_to :creator, class_name: "User", inverse_of: :created_budgets
end
