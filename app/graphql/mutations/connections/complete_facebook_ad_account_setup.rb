# frozen_string_literal: true

class Mutations::Connections::CompleteFacebookAdAccountSetup < Mutations::BaseMutation
  argument :facebook_ad_account_id, GraphQL::Types::ID, required: true
  argument :selected_fb_account_id, String, required: true

  field :facebook_ad_account, Types::Connections::FacebookAdAccountType, null: true

  def resolve(facebook_ad_account_id:, selected_fb_account_id:)
    fb_ad_account = context[:current_account].facebook_ad_accounts.find(facebook_ad_account_id)

    Connections::ConnectFacebook.new(context[:current_account], context[:current_account]).select_account_id(fb_ad_account, selected_fb_account_id)
    { facebook_ad_account: fb_ad_account }
  end
end
