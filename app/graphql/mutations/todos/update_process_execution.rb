class Mutations::Todos::UpdateProcessExecution < Mutations::BaseMutation
  argument :id, GraphQL::Types::ID, required: true
  argument :attributes, Types::Todos::ProcessExecutionAttributes, required: true

  field :process_execution, Types::Todos::ProcessExecutionType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(id:, attributes:)
    process_execution = context[:current_account].process_executions.kept.find(id)
    result, errors = Todos::UpdateProcessExecution.new(context[:current_account], context[:current_user]).update(process_execution, attributes.to_h)
    { process_execution: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
