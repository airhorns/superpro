# == Schema Information
#
# Table name: process_executions
#
#  id                  :bigint(8)        not null, primary key
#  discarded_at        :datetime
#  document            :json             not null
#  name                :string           not null
#  started_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint(8)        not null
#  creator_id          :bigint(8)        not null
#  owner_id            :bigint(8)        not null
#  process_template_id :bigint(8)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (owner_id => users.id)
#  fk_rails_...  (process_template_id => process_templates.id)
#

class ProcessExecution < ApplicationRecord
  include AccountScoped
  include Discard::Model
  include MutationClientId

  belongs_to :process_template, optional: true
  belongs_to :creator, class_name: "User", inverse_of: :created_process_executions
  belongs_to :owner, class_name: "User", inverse_of: :owned_process_executions
end
