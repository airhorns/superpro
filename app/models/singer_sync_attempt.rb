# == Schema Information
#
# Table name: singer_sync_attempts
#
#  id             :bigint(8)        not null, primary key
#  failure_reason :string
#  finished_at    :datetime
#  started_at     :datetime         not null
#  success        :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint(8)        not null
#  connection_id  :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (connection_id => connections.id)
#

class SingerSyncAttempt < ApplicationRecord
  include AccountScoped

  belongs_to :connection, optional: false
end
