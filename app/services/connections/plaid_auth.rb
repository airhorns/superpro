class Connections::PlaidAuth
  def initialize(account, user)
    @account = account
    @user = user
  end

  def complete_link(public_token)
    exchange_token_response = client.item.public_token.exchange(public_token)
    access_token = exchange_token_response["access_token"]
    item_id = exchange_token_response["item_id"]

    item = nil
    PlaidItem.transaction do
      item = @account.plaid_items.find_or_initialize_by(item_id: item_id)
      item.creator ||= @user
      item.access_token = access_token
      sync_accounts(item)
      item.save!

      connection = @account.connections.find_or_initialize_by(integration: item)
      connection.display_name = "Plaid Account (Item ID: #{item_id})"
      connection.save!
    end

    item
  end

  def sync_accounts(item)
    accounts_response = client.accounts.get(item.access_token)
    item.plaid_item_accounts = accounts_response["accounts"].map do |account_blob|
      PlaidItemAccount.new(account: @account, plaid_account_identifier: account_blob["account_id"], name: account_blob["name"], type: account_blob["type"], subtype: account_blob["subtype"])
    end
  end

  private

  def client
    @client ||= Plaid::Client.new(env: Rails.configuration.plaid.env,
                                  client_id: Rails.configuration.plaid.client_id,
                                  secret: Rails.configuration.plaid.secret,
                                  public_key: Rails.configuration.plaid.public_key)
  end
end
