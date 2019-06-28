class Types::Todos::ProcessTemplateAttributes < Types::BaseInputObject
  description "Attributes for creating or updating a process template"
  argument :name, String, "Name to set", required: false
  argument :document, Types::JSONScalar, "Opaque JSON document powering the document editor for the process template", required: false
end
