class AuthFailureApp < Devise::FailureApp
  def respond
    if client_side_auth?
      self.status = 401
      self.content_type = request.format.to_s

      i18n_options = { scope: "devise.failure", default: [warden_options[:message]], resource_name: "user" }
      auth_keys = User.authentication_keys
      keys = (auth_keys.respond_to?(:keys) ? auth_keys.keys : auth_keys).map { |key| User.human_attribute_name(key) }
      i18n_options[:authentication_keys] = keys.join(I18n.translate(:"support.array.words_connector"))

      self.response_body = { success: false, message: I18n.t("devise.failure.#{warden_options[:message]}", i18n_options) }.to_json
    else
      super
    end
  end

  def client_side_auth?
    request.format == :json
  end

  def scope_url
    auth_root_url
  end

  # Used by devise to figure out what URL to redirect to after login or whatnot. Because auth runs on a different domain, we need to
  # do something different than the default Devise behaviour and redirect to a different domain sometimes.
  def extract_path_from_location(location)
    uri = parse_uri(location)

    if uri
      if not [Rails.configuration.x.domains.app].include?(uri.host)
        path = remove_domain_from_uri(uri)
        path = add_fragment_back_to_path(uri, path)
      end

      path
    end
  end
end
