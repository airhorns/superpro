# frozen_string_literal: true

# == Schema Information
#
# Table name: business_lines
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  creator_id :bigint           not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

class BusinessLine < ApplicationRecord
  include AccountScoped
  belongs_to :creator, class_name: "User", optional: false

  validates :name, presence: true
end
