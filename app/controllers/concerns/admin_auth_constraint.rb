class AdminAuthConstraint
  def matches?(request)
    return !!request.session[:trestle_user]
  end
end
