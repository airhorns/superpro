require "google/apis/analyticsreporting_v4"
require "google/apis/analytics_v3"
require "google/api_client/client_secrets"

class Connections::ConnectGoogleAnalytics
  def initialize(account, user)
    @account = account
    @user = user
  end

  def connect_using_auth_hash(auth_hash)
    credential = @account.google_analytics_credentials.build(
      configured: false,
      creator: @user,
      token: auth_hash[:credentials][:token],
      refresh_token: auth_hash[:credentials][:token],
      expires_at: auth_hash[:credentials][:expires_at],
      grantor_email: auth_hash[:info][:email],
      grantor_name: auth_hash[:info][:name],
    )

    if credential.save
      return credential, nil
    else
      return nil, credential.errors
    end
  end

  def list_views(ga_credential)
    existing_configured_view_ids = @account.google_analytics_credentials.where(configured: true).pluck(:view_id).map(&:to_s).to_set

    service = service_for_credential(ga_credential)
    service.list_account_summaries.items.flat_map do |account|
      account.web_properties.flat_map do |property|
        property.profiles.flat_map do |profile|
          {
            id: profile.id,
            name: profile.name,
            property_id: property.id,
            property_name: property.name,
            account_id: account.id,
            account_name: account.name,
            already_setup: existing_configured_view_ids.include?(profile.id.to_s),
          }
        end
      end
    end
  end

  def select_view(ga_credential, view_id)
    service = service_for_credential(ga_credential)

    service.list_account_summaries.items.each do |account|
      account.web_properties.each do |property|
        property.profiles.each do |profile|
          if profile.id == view_id
            ga_credential.view_id = profile.id
            ga_credential.view_name = profile.name
            ga_credential.property_id = property.id
            ga_credential.property_name = property.name
            ga_credential.ga_account_id = account.id
            ga_credential.ga_account_name = account.name
          end
        end
      end
    end

    if ga_credential.view_id.present?
      GoogleAnalyticsCredential.transaction do
        ga_credential.configured = true
        ga_credential.save!

        connection = @account.connections.find_or_initialize_by(integration: ga_credential)
        connection.strategy = "singer"
        connection.display_name = "Google Analytics Account #{ga_credential.ga_account_name} - #{ga_credential.property_name} (View ID: #{ga_credential.view_id})"
        connection.save!

        Infrastructure::SyncSingerConnectionJob.enqueue(connection_id: connection.id)
      end
    end

    ga_credential
  end

  def refresh_access_token(ga_credential)
    signet_client = secrets_for_credential(ga_credential).to_authorization
    signet_client.refresh!
    if signet_client.access_token != ga_credential.token
      ga_credential.update(token: signet_client.access_token, refresh_token: signet_client.refresh_token, expires_at: signet_client.expires_at)
    end
    ga_credential
  end

  private

  def secrets_for_credential(ga_credential)
    Google::APIClient::ClientSecrets.new({
      "web" => { "access_token" => ga_credential.token,
                "refresh_token" => ga_credential.refresh_token,
                "client_id" => Rails.configuration.google[:google_oauth_client_id],
                "client_secret" => Rails.configuration.google[:google_oauth_client_secret] },
    })
  end

  def service_for_credential(ga_credential)
    service = Google::Apis::AnalyticsV3::AnalyticsService.new
    service.authorization = secrets_for_credential(ga_credential).to_authorization
    service
  end
end
