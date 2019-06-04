module Types
  class MutationErrorType < BaseObject
    description "Error object describing a reason why a mutation was unsuccessful, specific to a particular field."
    field :field, String, null: false, description: "The absolute name of the field relative to the root object that caused this error"
    field :relative_field, String, null: false, description: "The relative name of the field on the object (not necessarily the eroot) that cause this error"
    field :mutation_client_id, Types::MutationClientId, null: true, description: "The mutation client identifier for the object that caused this error"
    field :message, String, null: false, description: "Error message about the field without the field's name in it, like \"can't be blank\""
    field :full_message, String, null: false, description: "Error message about the field with the field's name in it, like \"title can't be blank\""

    # Formats an ActiveRecord::Errors into a format suitable to return by this type
    def self.format_errors_object(errors)
      return nil if errors.nil?
      errors.messages.flat_map do |field, messages|
        messages.map.with_index do |message, message_index|
          segments = field.to_s.split(".")
          details = errors.details[field][message_index] || {}

          {
            field: field.to_s.camelize(:lower),
            relative_field: segments[-1].camelize(:lower),
            message: message,
            mutation_client_id: details[:mutation_client_id] || mutation_client_id_for(segments, errors),
            full_message: errors.full_message(field, message),
          }
        end
      end
    end

    def self.mutation_client_id_for(segments, errors)
      object_path = segments[0...-1]
      object = errors.base

      if object_path.size > 0
        object = Rodash.get(object, object_path.join("."))
      end

      if object.present? && object.respond_to?(:mutation_client_id)
        object.mutation_client_id
      end
    end
  end
end
