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
// import "echarts/lib/component/title";
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
import { compact, uniq, flatMap, merge, isUndefined, clamp, truncate } from "lodash";
import { theme } from "superlib/EChartsTheme";
import { pivotGroupId } from "../../pivot";

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

const MAX_XAXIS_LABEL_LENGTH = 45;

const xAxesForBlock = (block: VizBlock, result: SuccessfulWarehouseQueryResult): EChartOption.XAxis[] => {
  const xIds = uniq(compact(block.viz.systems.map(system => system.xId)));
  if (xIds.length == 0) {
    return [{ type: "category", data: ["value"] }];
  }

  return xIds.map(xId => {
    const field = assert(result.outputIntrospection.fieldsById[xId]);
    const axisType = axisTypeForDataType(field.dataType);
    let nameGap = 48;
    let labelRotation = 0;

    if (axisType == "category") {
      let longestLabelLength = Math.max(
        ...result.records.map(record => {
          const val = record[xId];
          if (!isUndefined(val)) {
            return String(val).length;
          } else {
            return 0;
          }
        }),
        3
      );

      longestLabelLength = clamp(longestLabelLength, 0, MAX_XAXIS_LABEL_LENGTH);

      if (longestLabelLength > 3) {
        labelRotation = 90;
        nameGap = longestLabelLength * 11; // hack, roughly 11px per letter of a label
      } else {
      }
    }

    return merge({}, theme.xAxis, {
      id: xId,
      name: field.label,
      type: axisType,
      nameGap: nameGap,
      axisLabel: {
        interval: axisType == "category" ? 0 : undefined,
        rotate: labelRotation,
        formatter: (value: any) => truncate(String(value), { length: MAX_XAXIS_LABEL_LENGTH })
      }
    });
  });
};

const yAxesForBlock = (block: VizBlock, result: SuccessfulWarehouseQueryResult): EChartOption.YAxis[] => {
  const yIds = uniq(compact(block.viz.systems.map(system => system.yId)));
  const multiAxis = yIds.length > 1;

  return yIds.map((yId, index) => {
    const field = assert(result.outputIntrospection.fieldsById[yId] || result.outputIntrospection.pivotedMeasuresById[yId]);
    const axis: EChartOption.YAxis = merge({}, theme.yAxis, {
      id: yId,
      name: field.label,
      type: axisTypeForDataType(field.dataType),
      splitLine: {
        show: !multiAxis
      },
      axisLabel: {
        formatter: result.formatters[yId]
      },
      axisPointer: {
        label: {
          formatter: (obj: any) => {
            return result.formatters[yId](obj.value);
          }
        }
      }
    });

    if (multiAxis) {
      axis.axisLine = axis.axisLine || {};
      axis.axisLine.lineStyle = {
        color: theme.color[index]
      };
    }

    return axis;
  });
};

const seriesForBlock = (block: VizBlock, result: SuccessfulWarehouseQueryResult, yAxes: EChartOption.YAxis[]): EChartOption.Series[] => {
  const yAxisIndexById = yAxes.reduce<{ [id: string]: number }>((agg, yAxis, index) => {
    agg[assert(yAxis.id)] = index;
    return agg;
  }, {});

  return flatMap(block.viz.systems, system => {
    const yAxisIndex = yAxisIndexById[system.yId];

    if (system.segmentIds) {
      const measures = result.outputIntrospection.measuresByPivotGroupId[pivotGroupId(system)] || [];
      return measures.map(measure => {
        return {
          type: system.vizType,
          yAxisIndex: yAxisIndex,
          name: measure.label,
          encode: {
            x: system.xId,
            y: measure.id
          }
        };
      });
    } else {
      const field = assert(result.outputIntrospection.fieldsById[system.yId]);
      return {
        type: system.vizType,
        yAxisIndex: yAxisIndex,
        name: field.label,
        encode: {
          x: system.xId,
          y: system.yId
        }
      };
    }
  });
};

const dimensionsForBlock = (block: VizBlock, result: SuccessfulWarehouseQueryResult): EChartOption.Dataset.DimensionObject[] => {
  const dimensions = uniq(compact(block.viz.systems.map(system => system.xId))).map(xId => {
    const field = assert(result.outputIntrospection.fieldsById[xId]);
    return { name: xId, type: dimensionTypeForDataType(field.dataType) };
  });

  const measures = flatMap(block.viz.systems, system => {
    if (system.segmentIds) {
      const measures = result.outputIntrospection.measuresByPivotGroupId[pivotGroupId(system)] || [];
      return measures.map(measure => {
        return { name: measure.id, type: dimensionTypeForDataType(measure.dataType) };
      });
    } else {
      const field = assert(result.outputIntrospection.fieldsById[system.yId]);
      return { name: system.yId, type: dimensionTypeForDataType(field.dataType) };
    }
  });

  return dimensions.concat(measures);
};

export const heightForBlock = (block: VizBlock) => {
  switch (block.size) {
    case "medium":
    case undefined: {
      return "500px";
    }
    case "large": {
      return "900px";
    }
    case "xlarge": {
      return "1200px";
    }
    case "small": {
      return "300px";
    }
  }
};

export const EchartsPlotRenderer = (props: { result: SuccessfulWarehouseQueryResult; doc: ReportDocument; block: VizBlock }) => {
  const yAxes = yAxesForBlock(props.block, props.result);

  const option: EChartOption = {
    legend: {},
    grid: {
      containLabel: true
    },
    tooltip: {
      trigger: "axis",
      axisPointer: {
        type: "cross"
      }
      // formatter: params => {
      // This is complicated to even get the data out, see https://www.echartsjs.com/en/option.html#tooltip.formatter
      // params[0].value[params[0].dimensionNames[params[0].encode.y[0]]];
      // }
    },
    dataset: {
      dimensions: dimensionsForBlock(props.block, props.result),
      source: props.result.records
    },
    xAxis: xAxesForBlock(props.block, props.result),
    yAxis: yAxes,
    series: seriesForBlock(props.block, props.result, yAxes)
  };
  console.debug("Rendering chart", option);

  return (
    <ReactEchartsCore
      echarts={echarts}
      option={option}
      notMerge={true}
      lazyUpdate={true}
      style={{ height: heightForBlock(props.block), width: "100%" }}
      theme="superpro"
      opts={{ renderer: "svg" }}
    />
  );
};
