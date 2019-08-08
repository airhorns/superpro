module Types
  class AppQueryType < Types::BaseObject
    include Identity::IdentityQueries
    include Connections::ConnectionsQueries
  end
end
