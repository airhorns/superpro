# Adds a non-persisted attribute to models that allow calling code to add an opaque identifier to model instances passed into a service layer, and reassociate them on the way out.
# Useful for figuring out which input blob in a GraphQL mutation caused which validation errors after all the model instances have been created.
module MutationClientId
  extend ActiveSupport::Concern
  included do
    attribute :mutation_client_id, :string
  end
end
