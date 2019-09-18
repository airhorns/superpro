# frozen_string_literal: true

class Types::Infrastructure::AttachmentType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :content_type, String, null: false
  field :filename, String, null: false
  field :bytesize, Integer, null: false
  field :url, String, null: false

  def content_type
    load_blob.then(&:content_type)
  end

  def filename
    load_blob.then(&:filename)
  end

  def bytesize
    load_blob.then(&:byte_size)
  end

  def url
    Rails.application.routes.url_helpers.rails_blob_url(object, host: Rails.configuration.action_controller.asset_host, secure: true)
  end

  def load_blob
    AssociationLoader.for(ActiveStorage::Attachment, :blob).load(object)
  end
end
