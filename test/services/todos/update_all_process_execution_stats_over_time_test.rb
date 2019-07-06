require "test_helper"

class Todos::UpdateAllProcessExecutionStatsOverTimeTest < ActiveSupport::TestCase
  test "updates process executions with past closest_future_dates to their next closest future date" do
    execution_with_past_date = create(:process_execution)
    Timecop.freeze(Time.now.utc - 8.days) do
      setup_document(execution_with_past_date)
    end
    execution_with_future_date = create(:process_execution, account: execution_with_past_date.account, creator: execution_with_past_date.creator)
    setup_document(execution_with_future_date)

    assert execution_with_past_date.closest_future_deadline < Time.now.utc
    assert execution_with_future_date.closest_future_deadline > Time.now.utc

    Todos::UpdateAllProcessExecutionStatsOverTime.new.update_stats
    execution_with_past_date.reload
    execution_with_future_date.reload

    assert execution_with_past_date.closest_future_deadline > Time.now.utc
    assert execution_with_future_date.closest_future_deadline > Time.now.utc
  end

  private

  def setup_document(execution)
    UpdateProcessExecution.new(execution.account, execution.creator).update(execution, document: {
                                                                                         object: "document",
                                                                                         data: {},
                                                                                         nodes: [
                                                                                           {
                                                                                             object: "block",
                                                                                             type: "paragraph",
                                                                                             nodes: [
                                                                                               {
                                                                                                 object: "block",
                                                                                                 type: "deadline",
                                                                                                 data: {
                                                                                                   dueDate: (Time.now.utc - 10.days),

                                                                                                 },
                                                                                               },
                                                                                               {
                                                                                                 object: "block",
                                                                                                 type: "deadline",
                                                                                                 data: {
                                                                                                   dueDate: (Time.now.utc + 2.days),
                                                                                                 },
                                                                                               },
                                                                                               {
                                                                                                 object: "block",
                                                                                                 type: "deadline",
                                                                                                 data: {
                                                                                                   dueDate: (Time.now.utc + 10.days),
                                                                                                 },
                                                                                               },
                                                                                             ],
                                                                                           },
                                                                                         ],
                                                                                       })
    execution.reload
  end
end
