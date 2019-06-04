class Types::AuthMutationType < Types::BaseObject
  field :create_account, mutation: Mutations::Identity::CreateAccount
  field :discard_account, mutation: Mutations::Identity::DiscardAccount
end
