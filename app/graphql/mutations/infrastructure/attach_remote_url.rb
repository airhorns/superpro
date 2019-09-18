# frozen_string_literal: true

class Mutations::Infrastructure::AttachRemoteUrl < Mutations::BaseMutation
  argument :url, String, required: true
  argument :attachment_container_id, GraphQL::Types::ID, required: true
  argument :attachment_container_type, Types::Infrastructure::AttachmentContainerEnum, required: true

  field :attachment, Types::Infrastructure::AttachmentType, null: true
  field :errors, [String], null: true

  def resolve(url:, attachment_container_id:, attachment_container_type:)
    attachment, errors = Infrastructure::AttachRemoteUrl.new(context[:current_account], context[:current_user]).attach(
      attachment_container_type,
      attachment_container_id,
      url
    )

    { attachment: attachment, errors: errors }
  end
end
