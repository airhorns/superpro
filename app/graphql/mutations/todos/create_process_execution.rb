class Mutations::Todos::CreateProcessExecution < Mutations::BaseMutation
  argument :attributes, Types::Todos::ProcessExecutionAttributes, required: false

  field :process_execution, Types::Todos::ProcessExecutionType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(attributes: nil)
    result, errors = ::CreateProcessExecution.new(context[:current_account], context[:current_user]).create(attributes.try(:to_h))
    { process_execution: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
