# frozen_string_literal: true

module Types
  class AppQueryType < Types::BaseObject
    include Identity::IdentityQueries
    include Connections::ConnectionsQueries
    include Warehouse::WarehouseQueries
  end
end
