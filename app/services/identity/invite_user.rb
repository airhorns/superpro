# frozen_string_literal: true

class Identity::InviteUser
  def initialize(account, inviter)
    @account = account
    @inviter = inviter
  end

  def invite(attributes)
    success = false
    user = User.where(email: attributes[:email]).first

    Account.transaction do
      if !user
        user = User.invite!(attributes, @inviter)
      end

      if user.persisted?
        @account.account_user_permissions.find_or_create_by(user: user)
      end

      success = user.persisted?
    end

    if success
      return user, nil
    else
      return nil, user ? user.errors : nil
    end
  end
end
