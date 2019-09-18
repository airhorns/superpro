# frozen_string_literal: true

class Connections::PlaidTransactionSync
  def self.date_range_for_initial_sync(item)
    [item.created_at - 30.days, item.created_at]
  end

  def self.date_range_for_historical_sync(item)
    [item.created_at - 2.years, item.created_at]
  end

  def initialize(account, plaid_item)
    @account = account
    @item = plaid_item
  end

  def sync(date_start, date_end)
    paginate_transactions_endpoint(date_start, date_end) do |page|
      attributes_list = page["transactions"].map do |blob|
        {
          account_id: @account.id,
          plaid_item_id: @item.id,
          plaid_account_identifier: blob["account_id"],
          plaid_transaction_identifier: blob["transaction_id"],
          category: blob["category"],
          category_id: blob["category_id"],
          transaction_type: blob["transaction_type"],
          name: blob["name"],
          amount: blob["amount"].to_s,
          iso_currency_code: blob["iso_currency_code"],
          unofficial_currency_code: blob["unofficial_currency_code"],
          date: blob["date"],
          created_at: Time.now.utc,
          updated_at: Time.now.utc,
        }
      end

      PlaidTransaction.upsert_all(attributes_list)
    end
  end

  def remove_transaction_ids(ids)
  end

  private

  def paginate_transactions_endpoint(date_start, date_end)
    page_size = 100
    first_page = client.transactions.get(@item.access_token,
                                         date_start.strftime("%F"),
                                         date_end.strftime("%F"),
                                         count: page_size,
                                         offset: 0)
    total_pages = (first_page["total_transactions"].to_f / page_size).ceil

    yield first_page

    (1...total_pages).each do |page_num|
      yield client.transactions.get(@item.access_token,
                                    date_start.strftime("%F"),
                                    date_end.strftime("%F"),
                                    count: page_size,
                                    offset: page_size * page_num)
    end
  end

  def client
    @client ||= Plaid::Client.new(env: Rails.configuration.plaid.env,
                                  client_id: Rails.configuration.plaid.client_id,
                                  secret: Rails.configuration.plaid.secret,
                                  public_key: Rails.configuration.plaid.public_key)
  end
end
