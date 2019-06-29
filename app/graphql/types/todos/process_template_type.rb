class Types::Todos::ProcessTemplateType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
  field :creator, Types::Identity::UserType, null: false
  field :document, Types::JSONScalar, null: false

  field :execution_count, Integer, null: false
  field :last_execution, Types::Todos::ProcessExecutionType, null: true

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: false

  def execution_count
    AssociationLoader.for(ProcessTemplate, :process_executions).load(object).then { |records| records.size }
  end

  def last_execution
    object.process_executions.order(started_at: :desc, created_at: :desc).first
  end
end
