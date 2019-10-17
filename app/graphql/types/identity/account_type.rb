# frozen_string_literal: true

class Types::Identity::AccountType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
  field :creator, Types::Identity::UserType, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :business_epoch, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: true
  field :discarded, Boolean, null: false, method: :discarded?

  field :business_lines, [Types::Identity::BusinessLineType], null: false

  field :app_url, String, null: false

  def creator
    RecordLoader.for(User).load(object.creator_id)
  end

  def business_lines
    AssociationLoader.for(Account, :business_lines).load(object)
  end

  def app_url
    AccountHelper.app_url(object)
  end
end
