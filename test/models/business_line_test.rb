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

require "test_helper"

class BusinessLineTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
