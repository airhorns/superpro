class Mutations::Identity::CreateAccount < Mutations::BaseMutation
  argument :account, Types::Identity::AccountAttributes, required: true

  field :account, Types::Identity::AccountType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(account:)
    result, errors = Identity::CreateAccount.new(context[:current_user]).create(account.to_h)

    { account: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
