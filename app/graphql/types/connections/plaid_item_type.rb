class Types::Connections::PlaidItemType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :account_id, String, null: false
  field :creator, Types::Identity::UserType, null: false
  field :accounts, [Types::Connections::PlaidItemAccountType], null: false
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

  def creator
    RecordLoader.for(User).load(object.creator_id)
  end

  def accounts
    AssociationLoader.for(PlaidItem, :plaid_item_accounts).load(object)
  end
end
