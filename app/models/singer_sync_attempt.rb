# frozen_string_literal: true

# == Schema Information
#
# Table name: singer_sync_attempts
#
#  id               :bigint           not null, primary key
#  failure_reason   :string
#  finished_at      :datetime
#  last_progress_at :datetime         default(Tue, 01 Jan 2019 01:01:00 UTC +00:00), not null
#  started_at       :datetime         not null
#  success          :boolean
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  connection_id    :bigint           not null
#
# Indexes
#
#  index_singer_sync_attempts_on_created_at  (created_at)
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
