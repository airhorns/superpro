# frozen_string_literal: true

class App::ConnectionSessionsController < AppAreaController
  def create
    case params[:provider]
    when "google_analytics_oauth"
      ga_credential, errors = Connections::ConnectGoogleAnalytics.new(current_account, current_user).connect_using_auth_hash(auth_hash)
      if errors
        redirect_to connection_setup_error_path(provider: "Google Analytics")
      else
        redirect_to connection_setup_complete_path(provider: "google_analytics", integration_id: ga_credential.id, origin: origin)
      end
    when "shopify"
      _shopify_shop, errors = Connections::ConnectShopify.new(current_account, current_user).connect_using_auth_hash(auth_hash)
      if errors
        redirect_to connection_setup_error_path(provider: "Shopify")
      else
        redirect_to "#{origin}?#{{ success: "Shopify" }.to_param}"
      end
    when "facebook"
      fb_credential, errors = Connections::ConnectFacebook.new(current_account, current_user).connect_using_auth_hash(auth_hash)
      if errors
        redirect_to connection_setup_error_path(provider: "Facebook")
      else
        redirect_to connection_setup_complete_path(provider: "facebook", integration_id: fb_credential.id, origin: origin)
      end
    else
      raise "Unknown connection session provider callback"
    end
  end

  protected

  def auth_hash
    request.env["omniauth.auth"]
  end

  def origin
    URI(request.env["omniauth.origin"]).path
  rescue StandardError
    nil
  end
end
