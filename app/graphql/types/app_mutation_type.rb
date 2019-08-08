class Types::AppMutationType < Types::BaseObject
  # Identity
  field :invite_user, mutation: Mutations::Identity::InviteUser
  field :update_account, mutation: Mutations::Identity::UpdateAccount

  # Infrastructure
  field :attach_direct_uploaded_file, mutation: Mutations::Infrastructure::AttachDirectUploadedFile
  field :attach_remote_url, mutation: Mutations::Infrastructure::AttachRemoteUrl

  # Connections
  field :connect_plaid, mutation: Mutations::Connections::ConnectPlaid
  field :connect_shopify, mutation: Mutations::Connections::ConnectShopify
  field :restart_connection_sync, mutation: Mutations::Connections::RestartConnectionSync
end
