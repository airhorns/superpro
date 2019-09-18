# frozen_string_literal: true

module AccountScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account, optional: false
  end
end
