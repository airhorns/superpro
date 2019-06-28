class Mutations::Todos::CreateProcessTemplate < Mutations::BaseMutation
  argument :process_template, Types::Todos::ProcessTemplateAttributes, required: false

  field :process_template, Types::Todos::ProcessTemplateType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(attributes: nil)
    result, errors = ::CreateProcessTemplate.new(context[:current_account], context[:current_user]).create(attributes.try(:to_h))
    { process_template: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
