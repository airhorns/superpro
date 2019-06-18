import React from "react";
import { XAxis, YAxis, Tooltip, LineChart, Line, ReferenceLine, Brush } from "recharts";
import { ThemeContext } from "grommet";
import {
  DefaultBudgetTimeChartRange,
  DefaultTimeTickFormatter,
  DefaultTimeLabelFormatter,
  CurrencyValueFormatter,
  strokeForScenario
} from "./utils";
import { CubeChart } from "../../common";

export const BudgetTimeChart = React.memo((props: { budgetId: string }) => {
  const theme = React.useContext(ThemeContext) as any;

  return (
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
          }
        ],
        dimensions: ["BudgetForecasts.scenario"],
        renewQuery: true
      }}
      height={300}
      refreshKey="budgets:refresh"
    >
      {resultSet => {
        const data = resultSet.chartPivot();
        const seriesNames = resultSet.seriesNames();

        return (
          <LineChart data={data}>
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
            {seriesNames.map((name: any) => (
              <Line
                key={name.key}
                dataKey={name.key}
                name={name.title}
                dot={false}
                stroke={strokeForScenario(name.key.split(",")[0], theme)}
                animationDuration={500}
              />
            ))}
            <ReferenceLine y={0} stroke={theme.global.colors["status-error"]} strokeDasharray="3 3" />
            <Brush />
          </LineChart>
        );
      }}
    </CubeChart>
  );
});
