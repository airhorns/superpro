import React from "react";
import { Page, LinkButton } from "../common";
import gql from "graphql-tag";
import { GetBudgetForReportsComponent } from "app/app-graph";
import { BudgetContributorsReport } from "./reports/BudgetContributorsReport";
import { NotFoundPage } from "../chrome/NotFoundPage";
import { BudgetProblemSpotReport } from "./reports/BudgetProblemSpotReport";
import { Box } from "grommet";

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
    Component: BudgetProblemSpotReport
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
            <Box>
              <report.Component budgetId={data.budget.id} />
            </Box>
            <Box pad="small" gap="small" width="medium" margin={{ top: "small" }}>
              <LinkButton to={`/budget/${data.budget.id}/reports`} label="Back to Reports" />
              <LinkButton to={`/budget`} label="Back to Budget" />
            </Box>
          </Page.Layout>
        )}
      </Page.Load>
    );
  }
}
