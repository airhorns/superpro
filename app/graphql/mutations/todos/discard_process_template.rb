class Mutations::Todos::DiscardProcessTemplate < Mutations::BaseMutation
  argument :id, GraphQL::Types::ID, required: true

  field :process_template, Types::Todos::ProcessExecutionType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(id:)
    process_template = context[:current_account].process_templates.kept.find(id)
    result, errors = ::DiscardProcessTemplate.new(context[:current_account], context[:current_user]).discard(process_template)
    { process_template: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
