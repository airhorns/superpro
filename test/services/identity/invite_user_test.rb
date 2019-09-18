# frozen_string_literal: true

require "test_helper"

class Identity::InviteUserTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @inviter = Identity::InviteUser.new(@account, @account.creator)
  end

  test "it can invite a whole new user" do
    assert_difference "User.count", 1 do
      user, errors = @inviter.invite(email: "foo@bar.com")

      assert_nil errors
      assert_equal "foo@bar.com", user.email
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_match (/invit/i), ActionMailer::Base.deliveries.last.subject
      assert AccountUserPermission.where(user: user, account: @account).first
    end
  end

  test "it returns errors on the user when the user is invalid" do
    assert_difference "User.count", 0 do
      assert_difference "AccountUserPermission.count", 0 do
        user, errors = @inviter.invite(email: "")

        assert_not_nil errors
        assert_nil user
      end
    end
  end

  test "it can invite an existing user to an account it didn't have permission to before" do
    existing_user = create(:user)
    assert_nil AccountUserPermission.where(user: existing_user, account: @account).first

    assert_difference "User.count", 0 do
      _user, errors = @inviter.invite(email: existing_user.email)

      assert_nil errors
      assert_equal 0, ActionMailer::Base.deliveries.size
      assert AccountUserPermission.where(user: existing_user, account: @account).first
    end
  end

  test "it can invite an existing user who already has permissions and doesn't send an email" do
    existing_user = create(:user)
    AccountUserPermission.create!(user: existing_user, account: @account)

    assert_difference "User.count", 0 do
      assert_difference "AccountUserPermission.count", 0 do
        _user, errors = @inviter.invite(email: existing_user.email)
        assert_equal 0, ActionMailer::Base.deliveries.size
        assert_nil errors
      end
    end
  end
end
