# frozen_string_literal: true

class Identity::DiscardAccount
  def initialize(user)
    @user = user
  end

  def discard(account)
    Account.transaction do
      account.discard
    end

    [account, nil]
  end
end
