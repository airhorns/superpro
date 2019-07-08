class CreateTodoFeedItems < ActiveRecord::Migration[6.0]
  def change
    create_view :todo_feed_items
  end
end
