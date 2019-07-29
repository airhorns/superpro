# == Schema Information
#
# Table name: connections
#
#  id               :bigint(8)        not null, primary key
#  display_name     :string           not null
#  enabled          :boolean          default(TRUE), not null
#  integration_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint(8)        not null
#  integration_id   :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class Connection < ApplicationRecord
  include AccountScoped
  belongs_to :integration, polymorphic: true, optional: false, autosave: true
end
