import React from "react";
import { XAxis, YAxis, Tooltip, CartesianGrid, BarChart, Bar, ReferenceLine, Brush, Legend } from "recharts";
import { tickDateFormatter, DefaultBudgetTimeChartRange, colorScaleForSeries } from "./utils";
import { CubeChart } from "../../common";

export const BudgetContributorsReport = (props: { budgetId: string }) => {
  return (
    <CubeChart
      query={{
        measures: ["Budgets.amount"],
        timeDimensions: [
          {
            dimension: "Budgets.timestamp",
            granularity: "week",
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
        dimensions: ["Budgets.section"],
        renewQuery: true
      }}
      height={600}
      refreshKey="budgets:refresh"
    >
      {resultSet => {
        const colors = colorScaleForSeries(resultSet.seriesNames().length);
        return (
          <BarChart data={resultSet.chartPivot()} stackOffset="sign">
            <XAxis dataKey="x" tickFormatter={tickDateFormatter} />
            <YAxis type="number" />
            <CartesianGrid />
            <ReferenceLine y={0} stroke="#000" />
            <Tooltip labelFormatter={tickDateFormatter} />
            {resultSet.seriesNames().map((series: any, index: number) => (
              <Bar stackId="amounts" key={series.key} dataKey={series.key} name={series.title} fill={colors[index]} />
            ))}
            <Legend />
            <Brush />
          </BarChart>
        );
      }}
    </CubeChart>
  );
};
