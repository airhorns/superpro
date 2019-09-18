# frozen_string_literal: true

class App::ConnectionSessionsController < AppAreaController
  def create
    case params[:provider]
    when "google_analytics_oauth"
      ga_credential, errors = Connections::ConnectGoogleAnalytics.new(current_account, current_user).connect_using_auth_hash(auth_hash)
      if errors
        redirect_to "/settings/connections/error", provider: "Google Analytics"
      else
        redirect_to "/settings/connections/google_analytics/#{ga_credential.id}/complete"
      end
    else
      raise "Unknown connection session provider callback"
    end
  end

  protected

  def auth_hash
    request.env["omniauth.auth"]
  end
end
