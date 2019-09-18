# frozen_string_literal: true

# graphql-ruby requires this in order to provide accurate hasPreviousPage values... not exactly sure why it isn't on by default
GraphQL::Relay::ConnectionType.bidirectional_pagination = true
