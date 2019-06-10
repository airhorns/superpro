require "test_helper"

UPDATE_BUDGET_MUTATION = <<~QUERY
  mutation updateBudget($id: ID!, $budget: BudgetAttributes!) {
    updateBudget(id: $id, budget: $budget) {
      budget {
        id
        creator {
          id
        }
        budgetLines {
          description
          sortOrder
          amountScenarios
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
    result = FlurishAppSchema.execute(UPDATE_BUDGET_MUTATION, context: @context, variables: {
                                                                id: @budget.id,
                                                                budget: { "name": "Other budget", budgetLines: [] },
                                                              })
    assert_no_graphql_errors result
    assert_nil result["data"]["updateBudget"]["errors"]
    assert_equal @budget.id.to_s, result["data"]["updateBudget"]["budget"]["id"]
    assert_equal @budget.reload.name, "Other budget"
  end

  test "it can update a budget's lines" do
    line = @budget.budget_lines.first
    result = FlurishAppSchema.execute(UPDATE_BUDGET_MUTATION, context: @context, variables: {
                                                                id: @budget.id,
                                                                budget: { "name": "Other budget", budgetLines: [{
                                                                  id: line.id,
                                                                  description: line.description,
                                                                  section: line.section,
                                                                  recurrenceRules: [],
                                                                  sortOrder: 0,
                                                                  amountScenarios: {
                                                                    "default" => 1000,
                                                                    "optimistic" => 1500,
                                                                    "pessimistic" => 500,
                                                                  },
                                                                }] },
                                                              })
    assert_no_graphql_errors result
    assert_nil result["data"]["updateBudget"]["errors"]
    assert_equal @budget.id.to_s, result["data"]["updateBudget"]["budget"]["id"]
    assert_equal({ "default" => 1000, "optimistic" => 1500, "pessimistic" => 500 }, result["data"]["updateBudget"]["budget"]["budgetLines"][0]["amountScenarios"])
  end
end
