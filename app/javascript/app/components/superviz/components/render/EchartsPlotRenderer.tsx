import React from "react";
import ReactEchartsCore from "echarts-for-react/lib/core";
// then import echarts modules those you have used manually.
import echarts from "echarts/lib/echarts";
import { EChartOption } from "echarts";
import "echarts/lib/chart/line";
import "echarts/lib/chart/bar";
// import 'echarts/lib/chart/pie';
import "echarts/lib/chart/scatter";
// import 'echarts/lib/chart/radar';
// import 'echarts/lib/chart/map';
// import 'echarts/lib/chart/treemap';
// import 'echarts/lib/chart/graph';
// import 'echarts/lib/chart/gauge';
// import 'echarts/lib/chart/funnel';
// import 'echarts/lib/chart/parallel';
// import 'echarts/lib/chart/sankey';
// import 'echarts/lib/chart/boxplot';
// import 'echarts/lib/chart/candlestick';
// import 'echarts/lib/chart/effectScatter';
// import 'echarts/lib/chart/lines';
// import 'echarts/lib/chart/heatmap';
// import 'echarts/lib/component/graphic';
import "echarts/lib/component/grid";
import "echarts/lib/component/legend";
import "echarts/lib/component/tooltip";
// import 'echarts/lib/component/polar';
// import 'echarts/lib/component/geo';
// import 'echarts/lib/component/parallel';
// import 'echarts/lib/component/singleAxis';
// import 'echarts/lib/component/brush';
import "echarts/lib/component/title";
// import 'echarts/lib/component/dataZoom';
// import 'echarts/lib/component/visualMap';
// import 'echarts/lib/component/markPoint';
// import 'echarts/lib/component/markLine';
// import 'echarts/lib/component/markArea';
import "echarts/lib/component/timeline";
// import 'echarts/lib/component/toolbox';
// import 'zrender/lib/vml/vml';
// The usage of ReactEchartsCore are same with above.

import { SuccessfulWarehouseQueryResult } from "../GetWarehouseData";
import { ReportDocument, VizBlock } from "../..";
import { assert } from "superlib";
import { WarehouseDataTypeEnum } from "app/app-graph";
import { compact, uniq } from "lodash";

const palette = ["#cf3759", "#00429d", "#93003a", "#4771b2", "#a5d5d8", "#f4777f", "#ffbcaf", "#73a2c6"];

const axisTypeForDataType = (dataType: WarehouseDataTypeEnum): EChartOption.BasicComponents.CartesianAxis.Type => {
  if (dataType == "DateTime") {
    return "time";
  } else if (dataType == "String") {
    return "category";
  } else {
    return "value";
  }
};

const dimensionTypeForDataType = (dataType: WarehouseDataTypeEnum): EChartOption.Dataset.DimensionObject["type"] => {
  if (dataType == "DateTime") {
    return "time";
  } else if (dataType == "String") {
    return "ordinal";
  } else {
    return "number";
  }
};

const xAxesForBlock = (block: VizBlock, result: SuccessfulWarehouseQueryResult) => {
  const xIds = uniq(compact(block.viz.systems.map(system => system.xId)));
  return xIds.map(xId => {
    const field = assert(result.queryIntrospection.fieldsById[xId]);
    return {
      id: xId,
      name: field.label,
      type: axisTypeForDataType(field.dataType)
    };
  });
};

const yAxesForBlock = (block: VizBlock, result: SuccessfulWarehouseQueryResult) => {
  const yIds = uniq(compact(block.viz.systems.map(system => system.yId)));
  const showSplitLines = yIds.length == 1;

  return yIds.map((yId, index) => {
    const field = assert(result.queryIntrospection.fieldsById[yId]);
    return {
      id: yId,
      name: field.label,
      type: axisTypeForDataType(field.dataType),
      axisLine: {
        lineStyle: {
          color: palette[index]
        }
      },
      splitLine: {
        show: showSplitLines
      }
    };
  });
};

const seriesForBlock = (block: VizBlock, _result: SuccessfulWarehouseQueryResult) => {
  return block.viz.systems.map((system, index) => {
    return {
      type: system.vizType,
      yAxisIndex: index,
      encode: {
        x: system.xId,
        y: system.yId
      }
    };
  });
};

const dimensionsForBlock = (block: VizBlock, result: SuccessfulWarehouseQueryResult): EChartOption.Dataset.DimensionObject[] => {
  const dimensions = uniq(compact(block.viz.systems.map(system => system.xId))).map(xId => {
    const field = assert(result.queryIntrospection.fieldsById[xId]);
    return { name: xId, type: dimensionTypeForDataType(field.dataType) };
  });

  const measures = block.viz.systems.map(system => {
    const field = assert(result.queryIntrospection.fieldsById[system.yId]);
    return { name: system.yId, type: dimensionTypeForDataType(field.dataType) };
  });

  return dimensions.concat(measures);
};

export const EchartsPlotRenderer = (props: { result: SuccessfulWarehouseQueryResult; doc: ReportDocument; block: VizBlock }) => {
  const option: EChartOption = {
    legend: {},
    color: palette,
    tooltip: {
      trigger: "axis",
      axisPointer: {
        type: "cross"
      }
    },
    dataset: {
      dimensions: dimensionsForBlock(props.block, props.result),
      source: props.result.records
    },
    xAxis: xAxesForBlock(props.block, props.result),
    yAxis: yAxesForBlock(props.block, props.result),
    series: seriesForBlock(props.block, props.result)
  };
  console.debug("Rendering chart", option);

  return (
    <ReactEchartsCore
      echarts={echarts}
      option={option}
      notMerge={true}
      lazyUpdate={true}
      style={{ height: "100%" }}
      // theme={"theme_name"}
      // onChartReady={this.onChartReadyCallback}
      // onEvents={EventsDict}
      opts={{ renderer: "svg" }}
    />
  );
};
