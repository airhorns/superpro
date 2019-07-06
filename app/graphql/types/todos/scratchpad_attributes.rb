class Types::Todos::ScratchpadAttributes < Types::BaseInputObject
  description "Attributes for creating or updating a scratchpad"
  argument :document, Types::JSONScalar, "Opaque JSON document powering the document editor for the scratchpad", required: false
end
