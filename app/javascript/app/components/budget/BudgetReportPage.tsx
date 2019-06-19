import React from "react";
import { Box } from "grommet";
import { Page, LinkButton } from "../common";
import gql from "graphql-tag";
import { GetBudgetForReportsComponent } from "app/app-graph";
import { BudgetContributorsReport } from "./reports/BudgetContributorsReport";
import { NotFoundPage } from "../chrome/NotFoundPage";
import { BudgetProblemSpotReport } from "./reports/BudgetProblemSpotReport";
import { BudgetRunRateReport } from "./reports/BudgetRunRateReport";

gql`
  query GetBudgetForReports {
    budget: defaultBudget {
      id
      name
      sections
    }
  }
`;

export const Reports: { [key: string]: { title: string; description: string; Component: React.ComponentType<{ budgetId: string }> } } = {
  runRate: {
    title: "Run Rate",
    description: "View a simple revenue and expenses month to month forecast",
    Component: BudgetRunRateReport
  },
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

export default class BudgetReportPage extends Page<{ reportKey: string }> {
  render() {
    const report = Reports[this.props.match.params.reportKey];
    if (!report) {
      return <NotFoundPage />;
    }

    return (
      <Page.Load component={GetBudgetForReportsComponent} require={["budget"]}>
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
