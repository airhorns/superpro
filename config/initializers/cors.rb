# frozen_string_literal: true

Rails.configuration.middleware.insert_before 0, Rack::Cors do
end
