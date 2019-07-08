class Mutations::Todos::CreateScratchpad < Mutations::BaseMutation
  argument :attributes, Types::Todos::ScratchpadAttributes, required: false

  field :scratchpad, Types::Todos::ScratchpadType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(attributes: nil)
    result, errors = Todos::CreateScratchpad.new(context[:current_account], context[:current_user]).create(attributes.try(:to_h))
    { scratchpad: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
