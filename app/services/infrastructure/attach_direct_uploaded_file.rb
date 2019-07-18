# This implements a version of the form processing done by Rails' own direct upload functionality
# in a way that we can invoke it easier from the client side.
# See https://edgeguides.rubyonrails.org/active_storage_overview.html#direct-uploads for more details.
class Infrastructure::AttachDirectUploadedFile
  include Infrastructure::AttachmentContainerHelpers

  def initialize(account, user)
    @account = account
    @user = user
  end

  def attach(container_class, container_id, direct_upload_signed_id)
    resource = attachment_container(container_class, container_id)
    # #attach doesn't return the attachment, so we have to do the attach, then find the attachment corresponding to the blob passed in after
    blob = ActiveStorage::Blob.find_signed(direct_upload_signed_id)
    resource.files.attach(blob)
    attachment = resource.files_attachments.find_by(blob_id: blob.id)
    return attachment, nil
  end
end
