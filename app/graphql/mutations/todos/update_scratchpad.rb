class Mutations::Todos::UpdateScratchpad < Mutations::BaseMutation
  argument :id, GraphQL::Types::ID, required: true
  argument :attributes, Types::Todos::ScratchpadAttributes, required: true

  field :scratchpad, Types::Todos::ScratchpadType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(id:, attributes:)
    scratchpad = context[:current_account].scratchpads.kept.find(id)
    result, errors = Todos::UpdateScratchpad.new(context[:current_account], context[:current_user]).update(scratchpad, attributes.to_h)
    { scratchpad: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
