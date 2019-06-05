module AccountScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account, optional: false
  end
end
