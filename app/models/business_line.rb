# frozen_string_literal: true
class BusinessLine < ApplicationRecord
  include AccountScoped
  belongs_to :creator, class_name: "User", optional: false

  validates :name, presence: true
end
