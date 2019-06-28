class Types::Todos::ProcessExecutionAttributes < Types::BaseInputObject
  description "Attributes for creating or updating a process execution"
  argument :name, String, "Name to set", required: false
  argument :document, Types::JSONScalar, "Opaque JSON document powering the document editor for the process template", required: false
  argument :owner_id, GraphQL::Types::ID, "ID of the User to own this process's execution", required: false
  argument :process_template_id, GraphQL::Types::ID, "ID of the process template that spawned this execution", required: false
  argument :start_now, Boolean, required: false
end
