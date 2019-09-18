# frozen_string_literal: true

class Mutations::Identity::InviteUser < Mutations::BaseMutation
  argument :user, Types::Identity::UserInviteAttributes, required: true

  field :success, Boolean, null: false
  field :errors, [Types::MutationErrorType], null: true

  def resolve(user:)
    user, errors = Identity::InviteUser.new(context[:current_account], context[:current_user]).invite(user.to_h)

    { success: !!user, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
