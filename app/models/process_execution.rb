# == Schema Information
#
# Table name: process_executions
#
#  id                      :bigint(8)        not null, primary key
#  closed_todo_count       :integer          default(0), not null
#  closest_future_deadline :datetime
#  discarded_at            :datetime
#  document                :json             not null
#  name                    :string           not null
#  open_todo_count         :integer          default(0), not null
#  started_at              :datetime
#  total_todo_count        :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint(8)        not null
#  creator_id              :bigint(8)        not null
#  process_template_id     :bigint(8)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (process_template_id => process_templates.id)
#

class ProcessExecution < ApplicationRecord
  include AccountScoped
  include Discard::Model
  include MutationClientId

  validates :name, presence: true

  belongs_to :process_template, optional: true
  belongs_to :creator, class_name: "User", inverse_of: :created_process_executions, optional: false

  has_many :process_execution_involved_users, dependent: :destroy, autosave: true
  has_many :involved_users, class_name: "User", through: :process_execution_involved_users, source: :user
  has_many_attached :files
end
