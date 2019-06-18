module BaseClientSideAppSettings
  include ActiveSupport::Concern

  def base_settings
    return {
             devMode: Rails.env.development?,
             sentryDsn: ENV["FRONTEND_SENTRY_DSN"],
             authDomain: "https://#{Rails.configuration.x.domains.app}",
           }
  end
end
