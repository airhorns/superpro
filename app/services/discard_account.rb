class DiscardAccount
  def initialize(user)
    @user = user
  end

  def discard(account)
    Account.transaction do
      account.discard
    end

    return account, nil
  end
end
