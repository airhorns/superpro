# == Schema Information
#
# Table name: series
#
#  id                 :bigint(8)        not null, primary key
#  currency           :string
#  domain_type        :string           not null
#  range_type         :string           not null
#  scenario           :string           not null
#  series_domain_type :string           not null
#  series_range_type  :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint(8)        not null
#  creator_id         :bigint(8)        not null
#

class Series < ApplicationRecord
  include AccountScoped
  include MutationClientId

  enum range_type: { datetime: "datetime", number: "number", string: "string" }, _prefix: true
  enum domain_type: { money: "money", number: "number", string: "string" }, _prefix: true

  validates :scenario, presence: true

  belongs_to :creator, class_name: "User", inverse_of: :created_series
end
