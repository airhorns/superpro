import React from "react";
import { uniq, keyBy } from "lodash";
import shortid from "shortid";
import { Page } from "../common";
import { BudgetForm, BudgetFormValues } from "./BudgetForm";
import gql from "graphql-tag";
import { GetBudgetForEditComponent, GetBudgetForEditQuery } from "app/app-graph";
import { SuperForm } from "flurishlib/superform";
import { assert } from "flurishlib";

gql`
  query GetBudgetForEdit($budgetId: ID!) {
    budget(budgetId: $budgetId) {
      id
      name
      budgetLines {
        id
        description
        section
        recurrenceRules
        sortOrder
        amountScenarios
      }
    }
  }
`;

export default class EditBudgetPage extends Page<{ budgetId: string }> {
  processDataForForm(data: Exclude<GetBudgetForEditQuery["budget"], null>) {
    const sections = uniq(data.budgetLines.map(line => line.section)).map(section => ({ id: shortid(), name: section }));
    const sectionsIndex = keyBy(sections, "name");

    return {
      id: data.id,
      sections: sections,
      lines: data.budgetLines.map(line => ({
        id: line.id,
        sectionId: assert(sectionsIndex[line.section]).id,
        sortOrder: line.sortOrder,
        description: line.description,
        amountScenarios: line.amountScenarios,
        recurrenceRules: null
      }))
    };
  }

  render() {
    return (
      <Page.Layout title="Budget">
        <Page.Load component={GetBudgetForEditComponent} variables={{ budgetId: this.props.match.params.budgetId }} require={["budget"]}>
          {data => (
            <SuperForm<BudgetFormValues> initialValues={{ budget: this.processDataForForm(data.budget) }}>
              {form => <BudgetForm form={form} />}
            </SuperForm>
          )}
        </Page.Load>
      </Page.Layout>
    );
  }
}
