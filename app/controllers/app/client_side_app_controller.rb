class App::ClientSideAppController < AppAreaController
  include BaseClientSideAppSettings

  def index
    currency = Money::Currency.new("USD")
    currency_details = currency.as_json.slice("id", "symbol", "iso_code", "symbol").transform_keys! { |k| k.camelize(:lower) }
    currency_details[:exponent] = currency.exponent

    @settings = base_settings.merge({
      accountId: current_account.id,
      baseUrl: app_root_path(current_account),
      cubeJs: {
        apiUrl: Rails.configuration.cubejs.api_url,
        token: CubeJSAuth.token_for_user(current_user, current_account),
      },
      reportingCurrency: currency_details,
    })
  end
end
