class App::ClientSideAppController < AppAreaController
  def index
    @settings = {
      accountId: current_account.id,
      baseUrl: app_root_path(current_account),
      devMode: Rails.env.development?,
      cubeJs: {
        apiUrl: Rails.configuration.cubejs.api_url,
        token: CubeJSAuth.token_for_user(current_user, current_account),
      },
    }
  end
end
