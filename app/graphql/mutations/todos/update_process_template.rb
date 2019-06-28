class Mutations::Todos::UpdateProcessTemplate < Mutations::BaseMutation
  argument :id, GraphQL::Types::ID, required: true
  argument :attributes, Types::Todos::ProcessTemplateAttributes, required: true

  field :process_template, Types::Todos::ProcessTemplateType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(id:, attributes:)
    process_template = context[:current_account].process_templates.kept.find(id)
    result, errors = ::UpdateProcessTemplate.new(context[:current_account], context[:current_user]).update(process_template, attributes.to_h)
    { process_template: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
