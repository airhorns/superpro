require "test_helper"

GET_TODO_FEED_QUERY = <<~QUERY
  query GetMyTodoFeed {
    currentUser {
      todoFeedItems {
        nodes {
          id
          updatedAt
          todoSource {
            __typename
          }
        }
      }
    }
  }
QUERY

class TodoFeedIntegrationTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    @context = { current_account: @account, current_user: @account.creator }
    create_list(:process_execution, 3, account: @account, creator: @account.creator, started_at: Time.now.utc)
    create_list(:scratchpad, 3, account: @account, creator: @account.creator)
  end

  test "it can get the list of todo feed items for a user" do
    result = FlurishAppSchema.execute(GET_TODO_FEED_QUERY, context: @context)
    assert_no_graphql_errors result
    assert_equal 6, result["data"]["currentUser"]["todoFeedItems"]["nodes"].size
  end
end
