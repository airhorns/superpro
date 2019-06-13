import React from "react";
import { Page } from "../common";
import gql from "graphql-tag";
import { GetBudgetForReportsComponent } from "app/app-graph";
import { BudgetContributorsReport } from "./reports/BudgetContributorsReport";
import { NotFoundPage } from "../chrome/NotFoundPage";

gql`
  query GetBudgetForReports($budgetId: ID!) {
    budget(budgetId: $budgetId) {
      id
      name
      sections
    }
  }
`;

export const Reports: { [key: string]: { title: string; description: string; Component: React.ComponentType<{ budgetId: string }> } } = {
  contributors: {
    title: "Contributors",
    description: "View which pieces contribute the most to revenue and expenses",
    Component: BudgetContributorsReport
  },
  problemSpots: {
    title: "Problem Spots",
    description: "View times at which cash on hand is forecasted to go negative and ways to remedy this",
    Component: BudgetContributorsReport
  }
};

export default class BudgetReportPage extends Page<{ budgetId: string; reportKey: string }> {
  render() {
    const report = Reports[this.props.match.params.reportKey];
    if (!report) {
      return <NotFoundPage />;
    }

    return (
      <Page.Load component={GetBudgetForReportsComponent} variables={{ budgetId: this.props.match.params.budgetId }} require={["budget"]}>
        {data => (
          <Page.Layout title={`${data.budget.name} - ${report.title}`}>
            <report.Component budgetId={data.budget.id} />
          </Page.Layout>
        )}
      </Page.Load>
    );
  }
}
