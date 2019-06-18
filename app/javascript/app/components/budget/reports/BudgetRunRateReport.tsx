import React from "react";
import { XAxis, YAxis, Tooltip, CartesianGrid, BarChart, Bar, ReferenceLine, Brush, Legend } from "recharts";
import {
  DefaultTimeTickFormatter,
  DefaultBudgetTimeChartRange,
  DefaultTimeLabelFormatter,
  CurrencyValueFormatter,
  strokeForScenario
} from "./utils";
import { CubeChart } from "../../common";
import { ThemeContext } from "grommet";
import { darken, desaturate } from "polished";

export const BudgetRunRateReport = (props: { budgetId: string }) => {
  const theme = React.useContext(ThemeContext) as any;

  return (
    <CubeChart
      query={{
        measures: ["Budgets.revenue", "Budgets.expenses"],
        timeDimensions: [
          {
            dimension: "Budgets.timestamp",
            granularity: "month",
            dateRange: DefaultBudgetTimeChartRange
          }
        ],
        filters: [
          {
            member: "Budgets.budgetId",
            operator: "equals",
            values: [String(props.budgetId)]
          }
        ],
        dimensions: ["Budgets.scenario"],
        renewQuery: true
      }}
      height={600}
      refreshKey="budgets:refresh"
    >
      {resultSet => {
        return (
          <BarChart data={resultSet.chartPivot()} stackOffset="sign">
            <XAxis dataKey="x" tickFormatter={DefaultTimeTickFormatter} minTickGap={8} />
            <YAxis width={90} type="number" tickFormatter={CurrencyValueFormatter} />
            <CartesianGrid />
            <ReferenceLine y={0} stroke="#000" />
            <Tooltip labelFormatter={DefaultTimeLabelFormatter} formatter={CurrencyValueFormatter} />
            {resultSet.seriesNames().map((series: any) => {
              const scenario = series.key.split(",")[0];
              let fill = strokeForScenario(scenario, theme);
              if (series.key.includes("expense")) {
                fill = desaturate(0.1, darken(0.2, fill));
              }
              return <Bar stackId={scenario} key={series.key} dataKey={series.key} name={series.title} fill={fill} />;
            })}
            <Legend />
            <Brush />
          </BarChart>
        );
      }}
    </CubeChart>
  );
};
