require "test_helper"

UPDATE_BUDGET_MUTATION = <<~QUERY
  mutation updateBudget($budgetId: ID!, $budget: BudgetAttributes!) {
    updateBudget(budgetId: $budgetId, budget: $budget) {
      budget {
        id
        creator {
          id
        }
        budgetLines {
          description
          sortOrder
          value {
            ... on BudgetLineFixedValue {
              type
              occursAt
              recurrenceRules
              amountScenarios
            }
            ... on BudgetLineSeriesValue {
              type
              cells {
                dateTime
                amountScenarios
              }
            }
          }
        }
      }
      errors {
        field
        fullMessage
      }
    }
  }
QUERY

class UpdateBudgetIntegrationTest < ActiveSupport::TestCase
  setup do
    @budget = create(:base_operational_budget)
    @context = { current_account: @budget.account, current_user: @budget.creator }
  end

  test "it can update a budget's name" do
    result = FlurishAppSchema.execute(UPDATE_BUDGET_MUTATION, context: @context, variables: ActionController::Parameters.new({
                                                                budgetId: @budget.id,
                                                                budget: { "name": "Other budget", budgetLines: [] },
                                                              }))
    assert_no_graphql_errors result
    assert_nil result["data"]["updateBudget"]["errors"]
    assert_equal @budget.id.to_s, result["data"]["updateBudget"]["budget"]["id"]
    assert_equal @budget.reload.name, "Other budget"
  end

  test "it can create fixed budget lines" do
    result = FlurishAppSchema.execute(UPDATE_BUDGET_MUTATION, context: @context, variables: ActionController::Parameters.new({
                                                                budgetId: @budget.id,
                                                                budget: { "name": "Other budget", budgetLines: [{
                                                                  id: "nonsense",
                                                                  description: "Foobar",
                                                                  section: "Whatever",
                                                                  sortOrder: 0,
                                                                  value: {
                                                                    type: "fixed",
                                                                    occursAt: Time.now.utc.iso8601,
                                                                    recurrenceRules: [],
                                                                    amountScenarios: {
                                                                      "default" => 1000,
                                                                      "optimistic" => 1500,
                                                                      "pessimistic" => 500,
                                                                    },
                                                                  },
                                                                }] },
                                                              }))
    assert_no_graphql_errors result
    assert_nil result["data"]["updateBudget"]["errors"]
    assert_equal @budget.id.to_s, result["data"]["updateBudget"]["budget"]["id"]
    assert_equal 1, result["data"]["updateBudget"]["budget"]["budgetLines"].size
    assert_equal "fixed", result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["type"]
    assert_equal({ "default" => 1000, "optimistic" => 1500, "pessimistic" => 500 }, result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["amountScenarios"])
  end

  test "it can update a budget's lines with fixed line values" do
    line = @budget.budget_lines.first
    result = FlurishAppSchema.execute(UPDATE_BUDGET_MUTATION, context: @context, variables: ActionController::Parameters.new({
                                                                budgetId: @budget.id,
                                                                budget: { "name": "Other budget", budgetLines: [{
                                                                  id: line.id,
                                                                  description: line.description,
                                                                  section: line.section,
                                                                  sortOrder: 0,
                                                                  value: {
                                                                    type: "fixed",
                                                                    occursAt: Time.now.utc.iso8601,
                                                                    recurrenceRules: [],
                                                                    amountScenarios: {
                                                                      "default" => 1000,
                                                                      "optimistic" => 1500,
                                                                      "pessimistic" => 500,
                                                                    },
                                                                  },
                                                                }] },
                                                              }))
    assert_no_graphql_errors result
    assert_nil result["data"]["updateBudget"]["errors"]
    assert_equal @budget.id.to_s, result["data"]["updateBudget"]["budget"]["id"]
    assert_equal 1, result["data"]["updateBudget"]["budget"]["budgetLines"].size
    assert_equal "fixed", result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["type"]
    assert_equal({ "default" => 1000, "optimistic" => 1500, "pessimistic" => 500 }, result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["amountScenarios"])
  end

  test "it can create series budget lines" do
    result = FlurishAppSchema.execute(UPDATE_BUDGET_MUTATION, context: @context, variables: ActionController::Parameters.new({
                                                                budgetId: @budget.id,
                                                                budget: { "name": "Other budget", budgetLines: [{
                                                                  id: "nonsense",
                                                                  description: "Foobar",
                                                                  section: "Whatever",
                                                                  sortOrder: 0,
                                                                  value: {
                                                                    type: "series",
                                                                    cells: [
                                                                      { dateTime: Time.now.utc.iso8601, amountScenarios: {
                                                                        "default" => 1000,
                                                                        "optimistic" => 1500,
                                                                        "pessimistic" => 500,
                                                                      } },
                                                                      { dateTime: (Time.now.utc + 1.month).iso8601, amountScenarios: {
                                                                        "default" => 1001,
                                                                        "optimistic" => 1501,
                                                                        "pessimistic" => 501,
                                                                      } },
                                                                      { dateTime: (Time.now.utc + 2.months).iso8601, amountScenarios: {} },
                                                                    ],
                                                                  },
                                                                }] },
                                                              }))
    assert_no_graphql_errors result
    assert_nil result["data"]["updateBudget"]["errors"]
    assert_equal @budget.id.to_s, result["data"]["updateBudget"]["budget"]["id"]
    assert_equal 1, result["data"]["updateBudget"]["budget"]["budgetLines"].size
    assert_equal "series", result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["type"]
    assert_equal({ "default" => 1000, "optimistic" => 1500, "pessimistic" => 500 }, result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["cells"][0]["amountScenarios"])
    assert_nil result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["cells"][2]
  end

  test "it can change a budget's lines from fixed to series" do
    line = @budget.budget_lines.first
    result = FlurishAppSchema.execute(UPDATE_BUDGET_MUTATION, context: @context, variables: ActionController::Parameters.new({
                                                                budgetId: @budget.id,
                                                                budget: { "name": "Other budget", budgetLines: [{
                                                                  id: line.id,
                                                                  description: line.description,
                                                                  section: line.section,
                                                                  sortOrder: 0,
                                                                  value: {
                                                                    type: "series",
                                                                    cells: [
                                                                      { dateTime: Time.now.utc.iso8601, amountScenarios: {
                                                                        "default" => 1000,
                                                                        "optimistic" => 1500,
                                                                        "pessimistic" => 500,
                                                                      } },
                                                                    ],
                                                                  },
                                                                }] },
                                                              }))
    assert_no_graphql_errors result
    assert_nil result["data"]["updateBudget"]["errors"]
    assert_equal @budget.id.to_s, result["data"]["updateBudget"]["budget"]["id"]
    assert_equal 1, result["data"]["updateBudget"]["budget"]["budgetLines"].size
    assert_equal "series", result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["type"]
    assert_equal({ "default" => 1000, "optimistic" => 1500, "pessimistic" => 500 }, result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["cells"][0]["amountScenarios"])
  end

  test "it can create default budget lines with no data added yet" do
    result = FlurishAppSchema.execute(UPDATE_BUDGET_MUTATION, context: @context, variables: ActionController::Parameters.new({
                                                                budgetId: @budget.id,
                                                                budget: { "name": "Other budget", budgetLines: [{
                                                                  id: "nonsense",
                                                                  description: "",
                                                                  section: "Whatever",
                                                                  sortOrder: 0,
                                                                  value: {
                                                                    type: "fixed",
                                                                    occursAt: Time.now.utc.iso8601,
                                                                    recurrenceRules: [],
                                                                    amountScenarios: {},
                                                                  },
                                                                }] },
                                                              }))
    assert_no_graphql_errors result
    assert_nil result["data"]["updateBudget"]["errors"]
    assert_equal @budget.id.to_s, result["data"]["updateBudget"]["budget"]["id"]
    assert_equal 1, result["data"]["updateBudget"]["budget"]["budgetLines"].size
    assert_equal "", result["data"]["updateBudget"]["budget"]["budgetLines"][0]["description"]
    assert_equal({}, result["data"]["updateBudget"]["budget"]["budgetLines"][0]["value"]["amountScenarios"])
  end
end
