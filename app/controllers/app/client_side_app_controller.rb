# frozen_string_literal: true

class App::ClientSideAppController < AppAreaController
  include BaseClientSideAppSettings

  def index
    currency = Money::Currency.new("USD")
    currency_details = currency.as_json.slice("id", "symbol", "iso_code", "symbol").transform_keys! { |k| k.camelize(:lower) }
    currency_details[:exponent] = currency.exponent

    @settings = base_settings.merge(
      accountId: current_account.id,
      baseUrl: app_root_path(current_account),
      plaid: {
        publicKey: Rails.configuration.plaid.public_key,
        env: Rails.configuration.plaid.env,
        webhookUrl: connections_plaid_webhook_url,
      },
      reportingCurrency: currency_details,
    )
  end
end
