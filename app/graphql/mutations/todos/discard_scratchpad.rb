class Mutations::Todos::DiscardScratchpad < Mutations::BaseMutation
  argument :id, GraphQL::Types::ID, required: true

  field :scratchpad, Types::Todos::ScratchpadType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(id:)
    scratchpad = context[:current_account].scratchpads.kept.find(id)
    result, errors = Todos::DiscardScratchpad.new(context[:current_account], context[:current_user]).discard(scratchpad)
    { scratchpad: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
