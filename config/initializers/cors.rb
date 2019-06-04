Rails.configuration.middleware.insert_before 0, Rack::Cors do
  # Allow the edit world access to graphql on apps
  allow do
    origins Rails.configuration.x.domains.app
    resource "/graphql",
      headers: :any,
      methods: %i(get post put patch delete options head)
  end
end
