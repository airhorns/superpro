# frozen_string_literal: true

class Identity::SignUp
  def create_user_and_account(attributes)
    new_user = User.new(attributes[:user])
    new_account = nil
    success = false
    errors = nil

    User.transaction do
      if !new_user.save
        errors = new_user.errors
        raise ActiveRecord::Rollback
      end
      new_account, errors = Identity::CreateAccount.new(new_user).create(attributes[:account])

      if errors
        raise ActiveRecord::Rollback
      end

      success = true
    end

    if success
      return new_user, new_account, nil
    else
      return nil, nil, errors
    end
  end
end
