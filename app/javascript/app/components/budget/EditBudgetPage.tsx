import React from "react";
import _ from "lodash";
import shortid from "shortid";
import { Page } from "../common";
import { Formant } from "flurishlib/formant";
import { BudgetForm, BudgetFormValues } from "./BudgetForm";
import gql from "graphql-tag";
import { GetBudgetForEditComponent, GetBudgetForEditQuery } from "app/app-graph";

gql`
  query GetBudgetForEdit($budgetId: ID!) {
    budget(budgetId: $budgetId) {
      id
      name
      budgetLines {
        id
        description
        section
        variable
        recurrence
        sortOrder
        amount {
          fractional
        }
      }
    }
  }
`;

export default class EditBudgetPage extends Page<{ budgetId: string }> {
  processDataForForm(data: Exclude<GetBudgetForEditQuery["budget"], null>) {
    return {
      id: data.id,
      sections: Object.entries(_.groupBy(data.budgetLines, line => line.section)).map(([section, lines]) => ({
        name: section,
        key: shortid.generate(),
        lines: lines.map(line => ({
          id: line.id,
          key: line.id,
          description: line.description,
          variable: line.variable,
          amount: line.amount.fractional / 100,
          frequency: "daily"
        }))
      }))
    };
  }

  render() {
    return (
      <Page.Layout title="Budget">
        <Page.Load component={GetBudgetForEditComponent} variables={{ budgetId: this.props.match.params.budgetId }} require={["budget"]}>
          {data => (
            <Formant<BudgetFormValues> initialValues={{ budget: this.processDataForForm(data.budget) }} onSubmit={console.log}>
              {form => <BudgetForm form={form} />}
            </Formant>
          )}
        </Page.Load>
      </Page.Layout>
    );
  }
}
