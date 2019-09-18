# frozen_string_literal: true

# == Schema Information
#
# Table name: singer_global_sync_states
#
#  id         :bigint(8)        not null, primary key
#  key        :string           not null
#  state      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class SingerGlobalSyncState < ApplicationRecord
end
