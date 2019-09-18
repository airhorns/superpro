# frozen_string_literal: true

module CubeJSAuth
  def self.token_for_user(user, account)
    JWT.encode({ "u" => { "id" => user.id, "account_id" => account.id } }, Rails.configuration.cubejs.api_secret, "HS256")
  end
end
