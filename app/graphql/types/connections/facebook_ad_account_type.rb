# frozen_string_literal: true

class Types::Connections::FacebookAdAccountType < Types::BaseObject
  field :id, String, null: false
  field :configured, String, null: false
  field :fb_account_id, String, null: false
  field :fb_account_name, String, null: false
  field :grantor_name, String, null: false
  field :grantor_id, String, null: false
end
