# frozen_string_literal: true

class Identity::CreateAccount
  def initialize(creator)
    @creator = creator
  end

  def create(new_attributes)
    new_account = Account.new(creator_id: @creator.id)
    new_account.assign_attributes(new_attributes)
    new_account.account_user_permissions.build(user: @creator)
    new_account.business_lines.build(name: "Direct to Consumer", creator: @creator)

    success = new_account.save

    if success
      return new_account, nil
    else
      return nil, new_account.errors
    end
  end
end
