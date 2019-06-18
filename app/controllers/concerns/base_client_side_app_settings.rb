module BaseClientSideAppSettings
  include ActiveSupport::Concern

  def base_settings
    return {
             devMode: Rails.env.development?,
             clientSessionId: SecureRandom.uuid,
             sentryDsn: ENV["FRONTEND_SENTRY_DSN"],
             authDomain: "https://#{Rails.configuration.x.domains.app}",
             analytics: {
               identify: current_user.try(:id),
               identifyTraits: {
                 fullName: current_user.try(:full_name),
                 email: current_user.try(:email),
               },
               group: respond_to?(:current_account) && current_account.try(:id),
               groupTraits: {
                 name: respond_to?(:current_account) && current_account.try(:name),
               },
             },
           }
  end
end
