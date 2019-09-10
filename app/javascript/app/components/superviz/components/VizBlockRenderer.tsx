import React from "react";
import { ResponsiveContainer, ComposedChart, XAxis, YAxis, Line, CartesianGrid, Tooltip, Legend } from "recharts";
import { scaleTime, scaleLinear } from "d3-scale";
import { VizBlock, VizSystem, Document } from "../schema";
import { VizQuery, VizQueryContext, SuccessfulWarehouseQueryResult } from "./VizQuery";
import { flatMap, defaultTo } from "lodash";
import { DateTime } from "luxon";

type DomainTuple = [number, number];

const tickFormatter = (datatype: string, _domain: DomainTuple) => {
  if (datatype == "date_time") {
    return (date: Date) => DateTime.fromJSDate(date).toLocaleString(DateTime.DATE_MED);
  }

  return (x: any) => x;
};

const dataDomain = (result: SuccessfulWarehouseQueryResult, id: string): DomainTuple => {
  const data = result.records.map(record => record[id]);
  return [Math.min(...data), Math.max(...data)];
};

const renderSystem = (result: SuccessfulWarehouseQueryResult, system: VizSystem, index: number) => {
  const dependentVariableType = result.queryIntrospection.types[system.yId];
  const dependentVariableDomain: DomainTuple = dataDomain(result, system.yId);

  return [
    <YAxis
      key={`axis-${system.xId}-${system.yId}`}
      yAxisId={index}
      orientation={index == 0 ? "left" : "right"}
      domain={dependentVariableDomain}
      tickFormatter={tickFormatter(dependentVariableType, dependentVariableDomain)}
      padding={{ top: 20, bottom: 20 }}
    />,
    <Line key={`line-${system.xId}-${system.yId}`} yAxisId={index} dataKey={system.yId} />
  ];
};

export const VizBlockRenderer = (props: { doc: Document; block: VizBlock }) => (
  <VizQuery query={props.block.query}>
    <VizQueryContext.Consumer>
      {result => {
        const globalXId = props.block.viz.globalXId || props.block.viz.systems[0].xId;
        const xDomain = dataDomain(result, globalXId);
        const xDataType = result.queryIntrospection.types[globalXId];
        const xScale = xDataType == "date_time" ? scaleTime().domain(xDomain) : scaleLinear().domain(xDomain);

        return (
          <ResponsiveContainer>
            <ComposedChart
              data={result.records}
              syncId={(props.block.viz.globalSync && props.doc.id) || undefined}
              margin={{
                top: 20,
                right: 20,
                bottom: 20,
                left: 20
              }}
            >
              <XAxis
                dataKey={globalXId}
                padding={{ left: 10, right: 10 }}
                scale={xScale}
                ticks={xScale.ticks(5)}
                tickFormatter={tickFormatter(xDataType, xDomain)}
                type="number"
                domain={xDomain}
              />
              <CartesianGrid stroke="#ccc" strokeDasharray="5 5" />
              {flatMap(props.block.viz.systems, (system, index) => renderSystem(result, system, index))}
              {defaultTo(props.block.viz.showTooltip, true) && <Tooltip />}
              {defaultTo(props.block.viz.showLegend, true) && <Legend />}
            </ComposedChart>
          </ResponsiveContainer>
        );
      }}
    </VizQueryContext.Consumer>
  </VizQuery>
);
