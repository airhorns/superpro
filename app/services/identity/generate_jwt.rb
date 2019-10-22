# frozen_string_literal: true

class Identity::GenerateJwt
  def initialize(account)
    @account = account
  end

  def generate(user)
    # procedure copied from https://github.com/waiting-for-dev/devise-jwt/blob/master/lib/devise/jwt/test_helpers.rb
    # and https://github.com/waiting-for-dev/warden-jwt_auth/blob/master/lib/warden/jwt_auth/user_encoder.rb
    scope = Devise::Mapping.find_scope!(user)
    payload = Warden::JWTAuth::PayloadUserHelper.payload_for_user(user, scope).merge("aud" => nil)
    token = Warden::JWTAuth::TokenEncoder.new.call(payload)
    if user.respond_to?(:on_jwt_dispatch)
      user.on_jwt_dispatch(token, payload)
    end
    token
  end
end
