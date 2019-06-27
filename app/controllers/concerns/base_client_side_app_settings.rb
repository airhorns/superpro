module BaseClientSideAppSettings
  include ActiveSupport::Concern
  EXPORTED_FLAGS = ["feature.connections", "feature.tasks", "gate.publicSignUps"]

  def base_settings
    @base_settings ||= begin
      Flipper.preload(EXPORTED_FLAGS)

      {
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
        flags: EXPORTED_FLAGS.each_with_object({}) do |flag, obj|
          obj[flag] = Flipper[flag].enabled?(current_user)
        end,
      }
    end
  end
end
