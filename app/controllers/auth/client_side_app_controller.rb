class Auth::ClientSideAppController < ApplicationController
  include BaseClientSideAppSettings

  layout "auth_area_client_side_app"

  def index
    @settings = base_settings.merge({
      baseUrl: auth_root_path,
      signedIn: current_user.present?,
    })
  end
end
