class Mutations::Todos::DiscardProcessExecution < Mutations::BaseMutation
  argument :id, GraphQL::Types::ID, required: true

  field :process_execution, Types::Todos::ProcessExecutionType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(id:)
    process_execution = context[:current_account].process_executions.kept.find(id)
    result, errors = Todos::DiscardProcessExecution.new(context[:current_account], context[:current_user]).discard(process_execution)
    { process_execution: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
