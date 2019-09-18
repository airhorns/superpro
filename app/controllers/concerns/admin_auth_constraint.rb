# frozen_string_literal: true

class AdminAuthConstraint
  def matches?(request)
    !!request.session[:trestle_user]
  end
end
