# frozen_string_literal: true

# == Schema Information
#
# Table name: singer_global_sync_attempts
#
#  id               :bigint(8)        not null, primary key
#  failure_reason   :string
#  finished_at      :datetime
#  key              :string           not null
#  last_progress_at :datetime
#  started_at       :datetime
#  success          :boolean
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class SingerGlobalSyncAttempt < ApplicationRecord
end
