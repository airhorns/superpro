# frozen_string_literal: true

class Connections::ConnectFacebook
  def initialize(account, user)
    @account = account
    @user = user
  end

  def connect_using_auth_hash(auth_hash)
    credential = @account.facebook_ad_accounts.build(
      configured: false,
      creator: @user,
      access_token: auth_hash[:credentials][:token],
      expires_at: auth_hash[:credentials][:expires_at],
      grantor_id: auth_hash[:uid],
      grantor_name: auth_hash[:info][:name],
    )

    if credential.save
      return credential, nil
    else
      return nil, credential.errors
    end
  end

  def list_ad_accounts(fb_ad_account)
    existing_configured_ad_account_ids = @account.facebook_ad_accounts
      .includes(:connection)
      .where(configured: true)
      .to_a
      .filter { |account| account.connection.present? && !account.connection.discarded? }
      .map { |account| account.fb_account_id.to_s }

    available_ad_accounts(fb_ad_account).map do |ad_account|
      {
        id: ad_account.id,
        name: ad_account.name,
        account_status: ad_account.account_status,
        currency: ad_account.currency,
        age: ad_account.age,
        already_setup: existing_configured_ad_account_ids.include?(ad_account.id),
      }
    end
  end

  def select_account_id(fb_ad_account, selected_fb_account_id)
    available_ad_accounts(fb_ad_account).each do |available_account|
      next unless available_account.id == selected_fb_account_id
      fb_ad_account.fb_account_id = available_account.id
      fb_ad_account.fb_account_name = available_account.name
    end

    if fb_ad_account.fb_account_id.present?
      FacebookAdAccount.transaction do
        fb_ad_account.configured = true
        fb_ad_account.save!

        connection = @account.connections.kept.find_or_initialize_by(integration: fb_ad_account)
        connection.strategy = "singer"
        connection.display_name = "Facebook Ads Account #{fb_ad_account.fb_account_name} (Account ID: #{fb_ad_account.fb_account_id})"
        connection.save!

        Infrastructure::SingerConnectionSync.run_in_background(connection)
      end
    end

    fb_ad_account
  end

  def available_ad_accounts(fb_ad_account)
    fb_ad_account.with_session_active do |session|
      user = FacebookAds::User.get(fb_ad_account.grantor_id, session)
      user.adaccounts(fields: %w[name account_status currency age]).to_a
    end
  end
end
