# frozen_string_literal: true

class Mutations::Infrastructure::AttachDirectUploadedFile < Mutations::BaseMutation
  argument :direct_upload_signed_id, String, required: true
  argument :attachment_container_id, GraphQL::Types::ID, required: true
  argument :attachment_container_type, Types::Infrastructure::AttachmentContainerEnum, required: true

  field :attachment, Types::Infrastructure::AttachmentType, null: true
  field :errors, [String], null: true

  def resolve(direct_upload_signed_id:, attachment_container_id:, attachment_container_type:)
    attachment, errors = Infrastructure::AttachDirectUploadedFile.new(context[:current_account], context[:current_user]).attach(
      attachment_container_type,
      attachment_container_id,
      direct_upload_signed_id
    )

    { attachment: attachment, errors: errors }
  end
end
