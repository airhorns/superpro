class Identity::CreateAccount
  def initialize(creator)
    @creator = creator
  end

  def create(new_attributes)
    new_account = Account.new(creator_id: @creator.id)
    new_account.assign_attributes(new_attributes)
    new_account.account_user_permissions.build(user: @creator)

    success = false
    Account.transaction do
      if !new_account.save
        raise ActiveRecord::Rollback
      end
      Budget.create!(name: "Operational Budget", account: new_account, creator: @creator)

      success = true
    end

    if success
      return new_account, nil
    else
      return nil, new_account.errors
    end
  end
end
