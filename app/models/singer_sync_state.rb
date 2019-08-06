# == Schema Information
#
# Table name: singer_sync_states
#
#  id            :bigint(8)        not null, primary key
#  state         :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint(8)        not null
#  connection_id :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (connection_id => connections.id)
#

class SingerSyncState < ApplicationRecord
  include AccountScoped
  belongs_to :connection, optional: false, inverse_of: :singer_sync_state
end
