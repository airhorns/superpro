import React from "react";
import { uniq, keyBy, debounce, pick } from "lodash";
import shortid from "shortid";
import { Page, SavingNotice, SavingNoticeState } from "../common";
import { BudgetForm, BudgetFormValues, BudgetFormLineValue } from "./BudgetForm";
import gql from "graphql-tag";
import {
  GetBudgetForEditComponent,
  GetBudgetForEditQuery,
  UpdateBudgetComponent,
  UpdateBudgetMutationFn,
  BudgetLineValue,
  BudgetLineValueAttributes
} from "app/app-graph";
import { SuperForm } from "flurishlib/superform";
import { assert, mutationSuccess, toast } from "flurishlib";
import { BudgetTimeChart } from "./reports/BudgetTimeChart";
import { dispatch } from "use-bus";
import { DateTime } from "luxon";

gql`
  fragment BudgetForEdit on Budget {
    id
    name
    budgetLines {
      id
      description
      section
      sortOrder
      value {
        __typename
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

  query GetBudgetForEdit {
    budget: defaultBudget {
      ...BudgetForEdit
    }
  }

  mutation UpdateBudget($id: ID!, $attributes: BudgetAttributes!) {
    updateBudget(id: $id, attributes: $attributes) {
      budget {
        ...BudgetForEdit
      }
      errors {
        field
        fullMessage
      }
    }
  }
`;

export default class EditBudgetPage extends Page<{}, SavingNoticeState> {
  state: SavingNoticeState = { lastSaveAt: null, lastChangeAt: null };

  processLineValueForForm(data: BudgetLineValue): BudgetFormLineValue {
    if (data.__typename == "BudgetLineFixedValue") {
      return {
        type: "fixed",
        recurrenceRules: data.recurrenceRules || [],
        occursAt: data.occursAt,
        amountScenarios: data.amountScenarios
      };
    } else if (data.__typename == "BudgetLineSeriesValue") {
      return {
        type: "series",
        cells: keyBy(data.cells.map(cell => pick(cell, "dateTime", "amountScenarios")), cell => DateTime.fromISO(cell.dateTime).valueOf())
      };
    }
    throw new Error(`unknown value type for form ${data.type}`);
  }

  processDataForForm(data: Exclude<GetBudgetForEditQuery["budget"], null>): BudgetFormValues["budget"] {
    const sections = uniq(data.budgetLines.map(line => line.section)).map(section => ({ id: shortid(), name: section }));
    const sectionsIndex = keyBy(sections, "name");

    return {
      id: data.id,
      name: data.name,
      sections: sections,
      lines: data.budgetLines.map(line => ({
        id: line.id,
        sectionId: assert(sectionsIndex[line.section]).id,
        sortOrder: line.sortOrder,
        description: line.description,
        value: this.processLineValueForForm(line.value)
      }))
    };
  }

  debouncedSave = debounce(
    async (doc: BudgetFormValues, update: UpdateBudgetMutationFn) => {
      const sectionsIndex = keyBy(doc.budget.sections, "id");

      const result = await update({
        variables: {
          id: doc.budget.id,
          attributes: {
            budgetLines: doc.budget.lines.map(line => {
              let value: BudgetLineValueAttributes;
              if (line.value.type == "series") {
                value = {
                  ...line.value,
                  cells: Object.entries(line.value.cells).map(([millis, cell]) => ({
                    dateTime: DateTime.fromMillis(parseInt(millis, 10)).toISO(),
                    ...cell
                  }))
                };
              } else {
                value = line.value;
              }

              return {
                id: line.id,
                description: line.description,
                sortOrder: line.sortOrder,
                value: value,
                section: sectionsIndex[line.sectionId].name
              };
            })
          }
        }
      });
      if (mutationSuccess(result, "updateBudget")) {
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
