require "test_helper"

class CreateProcessExecutionTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @user = @account.permissioned_users.first
    @creator = ::CreateProcessExecution.new(@account, @user)
  end

  test "it creates a process execution" do
    assert_difference "ProcessExecution.count", 1 do
      result, errors = @creator.create(name: "A test process", document: CreateProcessTemplate::EMPTY_DOCUMENT)
      assert_nil errors
      assert_equal "A test process", result.name
      assert_equal [], result.involved_users
    end
  end

  test "it returns errors if the process execution is invalid" do
    assert_difference "ProcessExecution.count", 0 do
      result, errors = @creator.create(name: nil, document: CreateProcessTemplate::EMPTY_DOCUMENT)

      assert_not_nil errors
      assert_nil result
    end
  end
end
