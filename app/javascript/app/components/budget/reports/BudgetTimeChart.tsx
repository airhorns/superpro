import React from "react";
import { Area, XAxis, YAxis, Tooltip, AreaChart, ReferenceLine, Brush } from "recharts";
import { ThemeContext } from "grommet";
import { lighten } from "polished";
import { DefaultBudgetTimeChartRange, DefaultTimeTickFormatter, DefaultTimeLabelFormatter, CurrencyValueFormatter } from "./utils";
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
        dimensions: [],
        renewQuery: true
      }}
      height={300}
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
                <stop offset={zeroOffset} stopColor={lighten(0.3, theme.global.colors.brand)} stopOpacity={1} />
                <stop offset={zeroOffset} stopColor={lighten(0.3, theme.global.colors["status-error"])} stopOpacity={1} />
              </linearGradient>
              <linearGradient id="positiveIndicatorStroke" x1="0" y1="0" x2="0" y2="1">
                <stop offset={zeroOffset} stopColor={theme.global.colors.brand} stopOpacity={1} />
                <stop offset={zeroOffset} stopColor={theme.global.colors["status-error"]} stopOpacity={1} />
              </linearGradient>
            </defs>
            <ReferenceLine y={0} stroke={theme.global.colors["status-error"]} strokeDasharray="3 3" />
            <Brush />
          </AreaChart>
        );
      }}
    </CubeChart>
  );
});
