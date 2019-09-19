import React from "react";
import { ResponsiveContainer, ComposedChart, XAxis, YAxis, Line, CartesianGrid, Tooltip, Legend, Bar, XAxisProps } from "recharts";
import { scaleTime } from "d3-scale";
import { VizBlock, VizSystem, Document } from "../schema";
import { GetWarehouseData, VizQueryContext, SuccessfulWarehouseQueryResult } from "./GetWarehouseData";
import { flatMap, defaultTo, find } from "lodash";
import { DateTime } from "luxon";
import { Box, Heading } from "grommet";
import { assert } from "superlib";

type DomainTuple = [number, number];

const palette = ["#00429d", "#4771b2", "#73a2c6", "#a5d5d8", "#ffffe0", "#ffbcaf", "#f4777f", "#cf3759", "#93003a"];

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

  let marks: React.ReactNode;
  switch (system.vizType) {
    case "line": {
      marks = <Line key={`line-${system.xId}-${system.yId}`} yAxisId={index} dataKey={system.yId} stroke={palette[index]} />;
      break;
    }
    case "bar": {
      marks = <Bar key={`line-${system.xId}-${system.yId}`} yAxisId={index} dataKey={system.yId} fill={palette[index]} />;
      break;
    }
    default: {
      throw new Error(`Unknown viz type ${system.vizType}`);
    }
  }

  return [
    <YAxis
      key={`axis-${system.xId}-${system.yId}`}
      yAxisId={index}
      orientation={index == 0 ? "left" : "right"}
      domain={dependentVariableDomain}
      tickFormatter={tickFormatter(dependentVariableType, dependentVariableDomain)}
      padding={{ top: 20, bottom: 20 }}
      label={{
        value: assert(find(result.queryIntrospection.fields, { id: system.yId })).label,
        position: (index == 0 ? "insideLeft" : "right") as any,
        angle: index == 0 ? -90 : 90
      }}
    />,
    marks
  ];
};

const renderXAxis = (result: SuccessfulWarehouseQueryResult, block: VizBlock) => {
  const globalXId = block.viz.globalXId || block.viz.systems[0].xId;
  const domain = dataDomain(result, globalXId);
  const dataType = result.queryIntrospection.types[globalXId];

  const props: XAxisProps = {
    dataKey: globalXId,
    tickFormatter: tickFormatter(dataType, domain),
    label: {
      value: assert(find(result.queryIntrospection.fields, { id: globalXId })).label,
      position: "insideBottomRight"
    }
  };

  if (dataType == "date_time") {
    const scale = scaleTime().domain(domain);
    props.domain = domain;
    props.scale = scale;
    props.ticks = scale.ticks(5);
    props.padding = { left: 30, right: 30 };
    props.type = "number";
  }

  return <XAxis {...props} />;
};

export const VizBlockRenderer = (props: { doc: Document; block: VizBlock }) => (
  <GetWarehouseData query={props.block.query}>
    <VizQueryContext.Consumer>
      {result => {
        return (
          <Box fill>
            {props.block.title && <Heading level="3">{props.block.title}</Heading>}
            <ResponsiveContainer>
              <ComposedChart
                data={result.records}
                syncId={(props.block.viz.globalSync && props.doc.id) || undefined}
                margin={{
                  top: 30,
                  right: 30,
                  bottom: 30,
                  left: 30
                }}
              >
                <CartesianGrid stroke="#ccc" strokeDasharray="5 5" />
                {renderXAxis(result, props.block)}
                {flatMap(props.block.viz.systems, (system, index) => renderSystem(result, system, index))}
                {defaultTo(props.block.viz.showTooltip, true) && <Tooltip />}
                {defaultTo(props.block.viz.showLegend, true) && <Legend />}
              </ComposedChart>
            </ResponsiveContainer>
          </Box>
        );
      }}
    </VizQueryContext.Consumer>
  </GetWarehouseData>
);
