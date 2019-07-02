require "test_helper"

class UpdateProcessExecutionTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @user = @account.permissioned_users.first
    @updater = ::UpdateProcessExecution.new(@account, @user)
    @execution = create(:process_execution, account: @account, creator: @user)
  end

  test "it updates a process execution" do
    result, errors = @updater.update(@execution, { name: "New title" })
    assert_nil errors
    assert_equal "New title", result.name
    assert_equal [], result.involved_users
  end

  test "it updates a process execution and tracks involved users " do
    result, errors = @updater.update(@execution, { name: "New title", document: {
      "object": "document",
      "data": {},
      "nodes": [
        {
          "object": "block",
          "type": "check-list-item",
          "data": { "ownerId": @user.id.to_s },
          "nodes": [
            {
              "object": "text",
              "text": "Budget decided on",
              "marks": [],
            },
          ],
        },
      ],
    } })

    assert_nil errors
    assert_equal "New title", result.name
    assert_equal [@user], result.involved_users
  end

  test "it returns errors if the process execution is invalid" do
    result, errors = @updater.update(@execution, { name: nil, document: CreateProcessTemplate::EMPTY_DOCUMENT })

    assert_not_nil errors
    assert_nil result
  end
end
