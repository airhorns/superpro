# frozen_string_literal: true

# == Schema Information
#
# Table name: connections
#
#  id               :bigint           not null, primary key
#  discarded_at     :datetime
#  display_name     :string           not null
#  enabled          :boolean          default(TRUE), not null
#  integration_type :string           not null
#  strategy         :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  integration_id   :bigint           not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class Connection < ApplicationRecord
  include AccountScoped
  include Discard::Model

  belongs_to :integration, polymorphic: true, optional: false, autosave: true
  enum strategy: { singer: "singer", plaid: "plaid" }, _prefix: true
  validates :strategy, inclusion: { in: %w[singer plaid] }

  has_one :singer_sync_state, dependent: :destroy
  has_many :singer_sync_attempts, dependent: :destroy
end
