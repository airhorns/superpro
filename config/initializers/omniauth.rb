OmniAuth.config.logger = Rails.logger

HOST_CONSTRAINT_SETUP = lambda do |env|
  req = Rack::Request.new(env)
  if req.host != Rails.configuration.x.domains.app
    raise ActionController::RoutingError.new("Not Found")
  end
end

# This is the omniauth config that the *users* of superpro might interact with
# To OAuth against say Google's services for Superpro to extract data from google, they'd oauth here.
# There's other auth mechanisms for the app, including another Omniauth instance using google_oauth2 config, but for the admin system, that only Superpro employees might use.
Rails.application.config.middleware.use OmniAuth::Builder do
  options path_prefix: "/connection_auth"

  provider :google_oauth2, Rails.configuration.google[:google_oauth_client_id], Rails.configuration.google[:google_oauth_client_secret], name: "google_analytics_oauth", scope: "analytics.readonly", access_type: "offline", prompt: "consent", include_granted_scopes: "true", setup: HOST_CONSTRAINT_SETUP
end
