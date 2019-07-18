# == Schema Information
#
# Table name: process_templates
#
#  id           :bigint(8)        not null, primary key
#  discarded_at :datetime
#  document     :json             not null
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

class ProcessTemplate < ApplicationRecord
  include AccountScoped
  include Discard::Model
  include MutationClientId

  belongs_to :creator, class_name: "User", inverse_of: :created_process_templates
  has_many :process_executions, inverse_of: :process_template, dependent: :nullify
  has_many_attached :files
end
