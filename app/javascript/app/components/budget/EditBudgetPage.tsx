import React from "react";
import { uniq, keyBy, debounce, isNull, isUndefined, pickBy } from "lodash";
import shortid from "shortid";
import { Page, SavingNotice } from "../common";
import { BudgetForm, BudgetFormValues } from "./BudgetForm";
import gql from "graphql-tag";
import { GetBudgetForEditComponent, GetBudgetForEditQuery, UpdateBudgetComponent, UpdateBudgetMutationFn } from "app/app-graph";
import { SuperForm } from "flurishlib/superform";
import { assert, mutationSuccessful, toast } from "flurishlib";
import { BudgetTimeChart } from "./reports/BudgetTimeChart";
import { dispatch } from "use-bus";

gql`
  query GetBudgetForEdit {
    budget: defaultBudget {
      id
      name
      budgetLines {
        id
        description
        section
        occursAt
        recurrenceRules
        sortOrder
        amountScenarios
      }
    }
  }

  mutation UpdateBudget($budgetId: ID!, $budget: BudgetAttributes!) {
    updateBudget(budgetId: $budgetId, budget: $budget) {
      budget {
        id
        budgetLines {
          id
          section
          description
          occursAt
          sortOrder
          recurrenceRules
          amountScenarios
        }
      }
      errors {
        field
        fullMessage
      }
    }
  }
`;

interface EditBudgetPageState {
  lastSaveAt: null | Date;
  lastChangeAt: null | Date;
}

export default class EditBudgetPage extends Page<{}, EditBudgetPageState> {
  state: EditBudgetPageState = { lastSaveAt: null, lastChangeAt: null };

  processDataForForm(data: Exclude<GetBudgetForEditQuery["budget"], null>) {
    const sections = uniq(data.budgetLines.map(line => line.section)).map(section => ({ id: shortid(), name: section }));
    const sectionsIndex = keyBy(sections, "name");

    return {
      id: data.id,
      name: data.name,
      sections: sections,
      lines: data.budgetLines.map(line => ({
        id: line.id,
        sectionId: assert(sectionsIndex[line.section]).id,
        occursAt: line.occursAt,
        sortOrder: line.sortOrder,
        description: line.description,
        amountScenarios: line.amountScenarios,
        recurrenceRules:
          line.recurrenceRules && line.recurrenceRules.length > 0 ? { rrules: line.recurrenceRules, exdates: [], rdates: [] } : null
      }))
    };
  }

  debouncedSave = debounce(
    async (doc: BudgetFormValues, update: UpdateBudgetMutationFn) => {
      const sectionsIndex = keyBy(doc.budget.sections, "id");
      const result = await update({
        variables: {
          budgetId: doc.budget.id,
          budget: {
            budgetLines: doc.budget.lines.map(line => ({
              id: line.id,
              description: line.description,
              sortOrder: line.sortOrder,
              occursAt: line.occursAt,
              amountScenarios: pickBy(line.amountScenarios, value => !isNull(value) && !isUndefined(value)),
              recurrenceRules: line.recurrenceRules && line.recurrenceRules.rrules,
              section: sectionsIndex[line.sectionId].name
            }))
          }
        }
      });

      if (mutationSuccessful(result)) {
        this.setState({ lastSaveAt: new Date() });
        dispatch("budgets:refresh");
      } else {
        toast.error("There was an error saving your budget. Please try again.");
      }
    },
    1000,
    { leading: false }
  );

  handleChange = (doc: BudgetFormValues, update: UpdateBudgetMutationFn) => {
    this.setState({ lastChangeAt: new Date() });
    this.debouncedSave(doc, update);
  };

  render() {
    return (
      <Page.Load component={GetBudgetForEditComponent} require={["budget"]}>
        {data => (
          <Page.Layout
            title={data.budget.name}
            headerExtra={<SavingNotice lastChangeAt={this.state.lastChangeAt} lastSaveAt={this.state.lastSaveAt} />}
          >
            <BudgetTimeChart budgetId={data.budget.id} />
            <UpdateBudgetComponent>
              {update => (
                <SuperForm<BudgetFormValues>
                  initialValues={{ budget: this.processDataForForm(data.budget) }}
                  onChange={doc => this.handleChange(doc, update)}
                >
                  {form => <BudgetForm form={form} />}
                </SuperForm>
              )}
            </UpdateBudgetComponent>
          </Page.Layout>
        )}
      </Page.Load>
    );
  }
}
