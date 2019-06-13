import React from "react";
import { Page, LinkButton } from "../common";
import { GetBudgetForReportsComponent } from "app/app-graph";
import { Reports } from "./BudgetReportPage";
import { Box, Heading, Text } from "grommet";

export default class BudgetReportsIndexPage extends Page<{ budgetId: string }> {
  render() {
    return (
      <Page.Load component={GetBudgetForReportsComponent} variables={{ budgetId: this.props.match.params.budgetId }} require={["budget"]}>
        {data => (
          <Page.Layout title={data.budget.name}>
            {Object.entries(Reports).map(([key, report]) => (
              <LinkButton key={key} to={`/budget/${data.budget.id}/report/${key}`} hoverIndicator>
                <Box pad="small">
                  <Heading level="2">{report.title}</Heading>
                  <Text>{report.description}</Text>
                </Box>
              </LinkButton>
            ))}
            <Box pad="small" gap="small" width="medium" margin={{ top: "small" }}>
              <LinkButton to={`/budget`} label="Back to Budget" />
            </Box>
          </Page.Layout>
        )}
      </Page.Load>
    );
  }
}
