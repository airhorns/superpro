import React from "react";
import gql from "graphql-tag";
import { XAxis, YAxis, Tooltip, ReferenceLine, Brush, AreaChart, Area } from "recharts";
import { DefaultBudgetTimeChartRange, DefaultTimeTickFormatter, DefaultTimeLabelFormatter, CurrencyValueFormatter } from "./utils";
import { CubeChart } from "../../common";
import { ThemeContext, DataTable, Box, Text } from "grommet";
import { lighten } from "polished";
import { SimpleQuery } from "flurishlib";
import { GetBudgetProblemSpotsComponent } from "app/app-graph";
import { DateTime } from "luxon";

gql`
  query GetBudgetProblemSpots($budgetId: ID!) {
    budget(budgetId: $budgetId) {
      id
      problemSpots {
        startDate
        endDate
        minCashOnHand {
          formatted
        }
      }
    }
  }
`;

export const BudgetProblemSpotReport = (props: { budgetId: string }) => {
  const theme = React.useContext(ThemeContext) as any;

  return (
    <Box>
      <CubeChart
        query={{
          measures: ["BudgetForecasts.cashOnHand"],
          timeDimensions: [
            {
              dimension: "BudgetForecasts.timestamp",
              granularity: "week",
              dateRange: DefaultBudgetTimeChartRange
            }
          ],
          filters: [
            {
              member: "BudgetForecasts.budgetId",
              operator: "equals",
              values: [String(props.budgetId)]
            },
            {
              member: "BudgetForecasts.scenario",
              operator: "equals",
              values: ["default"]
            }
          ],
          renewQuery: true
        }}
        height={500}
        refreshKey="budgets:refresh"
      >
        {resultSet => {
          const data = resultSet.chartPivot();
          const gradientOffset = () => {
            const dataMax = Math.max(...data.map((row: any) => row["BudgetForecasts.cashOnHand"]));
            const dataMin = Math.min(...data.map((row: any) => row["BudgetForecasts.cashOnHand"]));

            if (dataMax <= 0) {
              return 0;
            } else if (dataMin >= 0) {
              return 1;
            } else {
              return dataMax / (dataMax - dataMin);
            }
          };

          const zeroOffset = gradientOffset();

          return (
            <AreaChart data={data}>
              <XAxis dataKey="x" tickFormatter={DefaultTimeTickFormatter} />
              <YAxis
                type="number"
                domain={[
                  dataMin => {
                    if (dataMin < 0) {
                      return dataMin;
                    } else if (dataMin == 0) {
                      return -10;
                    } else {
                      return dataMin;
                    }
                  },
                  "auto"
                ]}
                tickFormatter={CurrencyValueFormatter}
              />
              <Tooltip labelFormatter={DefaultTimeLabelFormatter} formatter={CurrencyValueFormatter} />
              <Area
                dataKey="BudgetForecasts.cashOnHand"
                stroke="url(#positiveIndicatorStroke)"
                fill="url(#positiveIndicatorFill)"
                animationDuration={500}
              />
              <defs>
                <linearGradient id="positiveIndicatorFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset={zeroOffset} stopColor={"#FFF"} stopOpacity={1} />
                  <stop offset={zeroOffset} stopColor={lighten(0.3, theme.global.colors["status-error"])} stopOpacity={1} />
                </linearGradient>
                <linearGradient id="positiveIndicatorStroke" x1="0" y1="0" x2="0" y2="1">
                  <stop offset={zeroOffset} stopColor={"#CCC"} stopOpacity={1} />
                  <stop offset={zeroOffset} stopColor={theme.global.colors["status-error"]} stopOpacity={1} />
                </linearGradient>
              </defs>
              <ReferenceLine y={0} stroke={theme.global.colors["status-error"]} strokeDasharray="3 3" />
              <Brush />
            </AreaChart>
          );
        }}
      </CubeChart>
      <Box>
        <SimpleQuery component={GetBudgetProblemSpotsComponent} variables={{ budgetId: props.budgetId }} require={["budget"]}>
          {data => (
            <DataTable
              columns={[
                {
                  property: "startDate",
                  header: "Start Date",
                  render: datum => DateTime.fromISO(datum.startDate).toLocaleString(DateTime.DATE_FULL)
                },
                {
                  property: "endDate",
                  header: "End Date",
                  render: datum => DateTime.fromISO(datum.endDate).toLocaleString(DateTime.DATE_FULL)
                },
                {
                  property: "minCashOnHand",
                  header: "Minimum Cash Available",
                  render: datum => <Text color="status-critical">{datum.minCashOnHand.formatted}</Text>,
                  primary: true
                }
              ]}
              data={data.budget.problemSpots}
            />
          )}
        </SimpleQuery>
      </Box>
    </Box>
  );
};
