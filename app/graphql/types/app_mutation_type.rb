# frozen_string_literal: true

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
  field :complete_google_analytics_setup, mutation: Mutations::Connections::CompleteGoogleAnalyticsSetup
  field :restart_connection_sync, mutation: Mutations::Connections::RestartConnectionSync
  field :sync_connection_now, mutation: Mutations::Connections::SyncConnectionNow
  field :set_connection_enabled, mutation: Mutations::Connections::SetConnectionEnabled
  field :discard_connection, mutation: Mutations::Connections::DiscardConnection
end
