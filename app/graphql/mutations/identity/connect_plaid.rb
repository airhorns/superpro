class Mutations::Identity::ConnectPlaid < Mutations::BaseMutation
  argument :public_token, String, required: true

  field :plaid_item, Types::Identity::PlaidItemType, null: true
  field :errors, [String], null: true

  def resolve(public_token:)
    account = context[:current_account]
    item, errors = Identity::PlaidAuth.new(context[:current_account], context[:current_user]).complete_link(public_token)
    if item
      {
        plaid_item: item,
        errors: nil,
      }
    else
      {
        plaid_item: nil,
        errors: ["There was an error connecting your Plaid account. Please try again."],
      }
    end
  end
end
