class Identity::UpdateAccount
  def initialize(account, user)
    @account = account
    @user = user
  end

  def update(account, attributes)
    success = Account.transaction do
      account.assign_attributes(attributes)
      account.save
    end

    if success
      return account, nil
    else
      return nil, account.errors
    end
  end
end
