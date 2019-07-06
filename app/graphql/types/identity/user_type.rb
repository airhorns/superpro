class Types::Identity::UserType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :full_name, String, null: false
  field :email, String, null: false

  field :locked, Boolean, null: false
  field :confirmed, Boolean, null: false

  field :involved_process_executions, Types::Todos::ProcessExecutionType.connection_type, null: false
  field :scratchpads, Types::Todos::ScratchpadType.connection_type, null: false
  field :todo_feed_items, Types::Todos::TodoFeedItemType.connection_type, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

  field :accounts, [Types::Identity::AccountType], null: false
  field :auth_area_url, String, null: false

  def accounts
    object.permissioned_accounts.kept
  end

  def involved_process_executions
    object.involved_process_executions.kept
  end

  def scratchpads
    context[:current_account].scratchpads.kept.for_user(context[:current_user])
  end

  def todo_feed_items
    context[:current_account].todo_feed_items.for_user(context[:current_user])
  end

  def auth_area_url
    Rails.application.routes.url_helpers.auth_root_url
  end
end
