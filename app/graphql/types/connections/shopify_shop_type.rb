# frozen_string_literal: true

class Types::Connections::ShopifyShopType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
  field :shopify_domain, String, null: false
  field :api_key, String, null: false
  field :shop_id, GraphQL::Types::ID, null: false

  field :connection, Types::Connections::ConnectionobjType, null: false, connection: false
  field :creator, Types::Identity::UserType, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

  def creator
    RecordLoader.for(User).load(object.creator_id)
  end

  def connection
    AssociationLoader.for(ShopifyShop, :connection).load(object)
  end
end
