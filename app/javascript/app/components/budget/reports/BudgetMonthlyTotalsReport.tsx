import React from "react";
import { flatMap, groupBy, sumBy } from "lodash";
import { DefaultBudgetTimeChartRange, CurrencyValueFormatter } from "./utils";
import { CubeChart } from "../../common";
import { DataTable, Box, Text } from "grommet";
import { DateTime } from "luxon";

export const BudgetMonthlyTotalsReport = (props: { budgetId: string }) => {
  return (
    <CubeChart
      query={{
        measures: ["Budgets.amount"],
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
          },
          {
            member: "Budgets.scenario",
            operator: "equals",
            values: ["default"]
          }
        ],
        dimensions: ["Budgets.lineName", "Budgets.section"],
        renewQuery: true
      }}
      refreshKey="budgets:refresh"
    >
      {resultSet => {
        let data = resultSet.pivot({ x: ["Budgets.lineName", "Budgets.section"], y: ["Budgets.timestamp"] });
        data = flatMap(
          Object.entries(groupBy(data, (datum: any) => datum.xValues[1])).map(([section, group]) => {
            const yValuesSums = group[0].yValuesArray.map((yValueTuple: any, index: number) => [
              yValueTuple[0],
              sumBy(group, (item: any) => parseInt(item.yValuesArray[index][1] || 0, 10))
            ]);
            return [{ group: true, xValues: [undefined, section], yValuesArray: yValuesSums }, ...group];
          })
        );
        const columns = resultSet.seriesNames({ x: ["Budgets.lineName", "Budgets.section"], y: ["Budgets.timestamp"] });

        return (
          <Box overflow={{ horizontal: "auto" }}>
            <DataTable
              columns={[
                {
                  property: "category",
                  header: <Text>Line</Text>,
                  primary: true,
                  render: (datum: any) => (
                    <Box width="small" pad={{ left: datum.group ? undefined : "small" }}>
                      {datum.group || <Text>{datum.xValues[0]}</Text>}
                      {datum.group && <Text weight="bold">{datum.xValues[1]}</Text>}
                    </Box>
                  )
                }
              ].concat(
                columns.map((column: any, index: number) => ({
                  property: column.key,
                  header: <Text>{DateTime.fromISO(column.key.split(",")[0]).toFormat("LLL yy")}</Text>,
                  render: (datum: any) => {
                    return (
                      <Text weight={datum.group ? "bold" : undefined}>
                        {CurrencyValueFormatter(parseInt(datum.yValuesArray[index][1] || 0, 10))}
                      </Text>
                    );
                  }
                }))
              )}
              data={data}
            />
          </Box>
        );
      }}
    </CubeChart>
  );
};
