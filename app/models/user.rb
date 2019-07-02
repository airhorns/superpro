# == Schema Information
#
# Table name: users
#
#  id                     :bigint(8)        not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           not null
#  encrypted_password     :string           not null
#  failed_attempts        :integer          default(0), not null
#  full_name              :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  locked_at              :datetime
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  unconfirmed_email      :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#

class User < ApplicationRecord
  include MutationClientId

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable, :lockable, :timeoutable, :trackable

  # Creations
  has_many :created_accounts, foreign_key: :creator_id, inverse_of: :creator, class_name: "Account", dependent: :restrict_with_exception
  has_many :created_budgets, foreign_key: :creator_id, inverse_of: :creator, class_name: "Budget", dependent: :restrict_with_exception
  has_many :created_budget_lines, foreign_key: :creator_id, inverse_of: :creator, class_name: "BudgetLine", dependent: :restrict_with_exception
  has_many :created_series, foreign_key: :creator_id, inverse_of: :creator, class_name: "Series", dependent: :restrict_with_exception
  has_many :created_process_templates, foreign_key: :creator_id, inverse_of: :creator, class_name: "ProcessTemplate", dependent: :restrict_with_exception
  has_many :created_process_executions, foreign_key: :creator_id, inverse_of: :creator, class_name: "ProcessExecution", dependent: :restrict_with_exception

  # Todos
  has_many :process_execution_involved_users, dependent: :restrict_with_exception
  has_many :involved_process_executions, through: :process_execution_involved_users, source: :process_execution

  # Auth
  has_many :account_user_permissions, inverse_of: :user, dependent: :destroy
  has_many :permissioned_accounts, through: :account_user_permissions, source: :account

  validates :full_name, presence: true

  def flipper_id
    @flipper_id ||= "user-#{id}"
  end
end
