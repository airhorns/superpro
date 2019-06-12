import React from "react";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import { QueryRenderer } from "@cubejs-client/react";
import { PageLoadSpin } from "flurishlib";
import { CubeJSAPI } from "../../lib/cubejs";
import { DateTime } from "luxon";
import { isNumber } from "lodash";

const dateFormatter = (date: string | number) => {
  let dateTime: DateTime;
  if (isNumber(date)) {
    dateTime = DateTime.fromMillis(date);
  } else {
    dateTime = DateTime.fromISO(date);
  }

  return dateTime.toFormat("MM YYYY");
};

export const BudgetTimeChart = (props: { budgetId: string }) => {
  return (
    <QueryRenderer
      query={{
        measures: ["BudgetForecasts.cashOnHand", "BudgetForecasts.revenue", "BudgetForecasts.expenses"],
        timeDimensions: [
          {
            dimension: "BudgetForecasts.timestamp",
            granularity: "week",
            dateRange: ["2019-01-01", "2020-01-01"]
          }
        ],
        filters: [],
        dimensions: []
      }}
      cubejsApi={CubeJSAPI}
      render={({ resultSet }: { resultSet: any }) => {
        let content: React.ReactNode;
        if (resultSet) {
          content = (
            <LineChart data={resultSet.chartPivot()}>
              <XAxis dataKey="x" tickFormatter={dateFormatter} />
              <YAxis />
              <Tooltip labelFormatter={dateFormatter} />
              <Line dataKey="BudgetForecasts.cashOnHand" stroke="rgba(106, 110, 229)" />
              <Line dataKey="BudgetForecasts.revenue" stroke="black" />
              <Line dataKey="BudgetForecasts.expenses" stroke="red" />
            </LineChart>
          );
        } else {
          content = <PageLoadSpin />;
        }

        return (
          <ResponsiveContainer width="100%" height={300}>
            {content}
          </ResponsiveContainer>
        );
      }}
    />
  );
};
