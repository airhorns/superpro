class Mutations::Identity::DiscardAccount < Mutations::BaseMutation
  argument :id, GraphQL::Types::ID, required: true

  field :account, Types::Identity::AccountType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(id:)
    account = context[:current_user].permissioned_accounts.find(id)
    result, errors = Identity::DiscardAccount.new(context[:current_user]).discard(account)

    { account: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
