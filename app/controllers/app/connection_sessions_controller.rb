class App::ConnectionSessionsController < AppAreaController
  def create
    puts auth_hash
    redirect_to "/settings/connections"
  end

  protected

  def auth_hash
    request.env["omniauth.auth"]
  end
end
