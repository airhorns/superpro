class Mutations::Identity::UpdateAccount < Mutations::BaseMutation
  argument :attributes, Types::Identity::AccountAttributes, required: true

  field :account, Types::Identity::AccountType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(attributes:)
    account = context[:current_account]
    result, errors = Identity::UpdateAccount.new(context[:current_account], context[:current_user]).update(account, attributes.to_h)
    { account: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
