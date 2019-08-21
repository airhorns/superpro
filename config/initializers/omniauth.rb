OmniAuth.config.logger = Rails.logger

# This is the omniauth config that the *users* of superpro might interact with
# To OAuth against say Google's services for Superpro to extract data from google, they'd oauth here.
# There's other auth mechanisms for the app, including another Omniauth instance using google_oauth2 config, but for the admin system, that only Superpro employees might use.
AppOmniauthStack = OmniAuth::Builder.new(Rails.application) do
  provider :google_oauth2, Rails.application.config.google[:google_oauth_client_id], Rails.application.config.google[:google_oauth_client_secret]
end
