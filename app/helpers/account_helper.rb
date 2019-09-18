# frozen_string_literal: true

module AccountHelper
  def self.app_url(account)
    Rails.application.routes.url_helpers.app_root_url(protocol: "https", params: { account_id: account.id })
  end
end
