module Auth
  class ClientSideAppController < ApplicationController
    layout "auth_area_client_side_app"

    def index
      @settings = {
        baseUrl: auth_root_path,
        signedIn: current_user.present?,
        devMode: Rails.env.development?,
        sentryDsn: ENV["FRONTEND_SENTRY_DSN"],
      }
    end
  end
end
