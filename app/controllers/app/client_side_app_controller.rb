class App::ClientSideAppController < AppAreaController
  def index
    @settings = {
      accountId: current_account.id,
      baseUrl: app_root_path(current_account),
      devMode: Rails.env.development?,
    }
  end
end
