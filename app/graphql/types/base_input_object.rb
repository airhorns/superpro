class Types::BaseInputObject < GraphQL::Schema::InputObject
  argument :mutation_client_id, Types::MutationClientId, "An opaque identifier that will appear on objects created/updated because of this attributes hash, or on errors from it being invalid.", required: false
end
