module Types
  class AppQueryType < Types::BaseObject
    include Identity::IdentityQueries
    include Budget::BudgetQueries
  end
end
