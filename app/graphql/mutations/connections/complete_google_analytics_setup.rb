class Mutations::Connections::CompleteGoogleAnalyticsSetup < Mutations::BaseMutation
  argument :credential_id, GraphQL::Types::ID, required: true
  argument :view_id, String, required: true

  field :google_analytics_credential, Types::Connections::GoogleAnalyticsCredentialType, null: true

  def resolve(credential_id:, view_id:)
    credential = context[:current_account].google_analytics_credentials.find(credential_id)
    Connections::ConnectGoogleAnalytics.new(context[:current_account], context[:current_account]).select_view(credential, view_id)
    { google_analytics_credential: credential }
  end
end
