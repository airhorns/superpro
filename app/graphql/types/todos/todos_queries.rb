module Types::Todos::TodosQueries
  extend ActiveSupport::Concern

  included do
    field :process_template, Types::Todos::ProcessTemplateType, null: true do
      description "Find a process template by ID"
      argument :id, GraphQL::Types::ID, required: true
    end

    field :process_templates, Types::Todos::ProcessTemplateType.connection_type, null: false, description: "Get all the process templates"

    field :process_execution, Types::Todos::ProcessExecutionType, null: true do
      description "Find a process execution by ID"
      argument :id, GraphQL::Types::ID, required: true
    end

    field :process_executions, Types::Todos::ProcessExecutionType.connection_type, null: false, description: "Get all the process executions"

    field :scratchpad, Types::Todos::ScratchpadType, null: true do
      description "Find a scratchpad by ID"
      argument :id, GraphQL::Types::ID, required: true
    end

    field :scratchpads, Types::Todos::ScratchpadType.connection_type, null: false, description: "Get all the scratchpads for the current user"
  end

  def process_executions
    context[:current_account].process_executions.kept.all
  end

  def process_execution(id:)
    context[:current_account].process_executions.kept.find_by(id: id)
  end

  def process_templates
    context[:current_account].process_templates.kept.all
  end

  def process_template(id:)
    context[:current_account].process_templates.kept.find_by(id: id)
  end

  def scratchpads
    context[:current_account].scratchpads.kept.for_user(context[:current_user]).all
  end

  def scratchpad(id:)
    context[:current_account].scratchpads.kept.for_user(context[:current_user]).find_by(id: id)
  end
end
