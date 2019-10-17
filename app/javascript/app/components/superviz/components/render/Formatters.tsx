import Dinero from "dinero.js";
import { DateTime, Duration } from "luxon";
import { isString, round } from "lodash";
import { OutputIntrospection } from "../GetWarehouseData";
import { WarehouseDataTypeEnum, WarehouseIntrospectionMeasureField, WarehouseIntrospectionDimensionField } from "app/app-graph";

export type FormatterFns = {
  [id: string]: (value: any) => string;
};

export const formattersForOutput = (output: OutputIntrospection): FormatterFns => {
  const formatters: FormatterFns = {};
  const measureEntries = Object.entries(output.measuresById).concat(Object.entries(output.pivotedMeasuresById));
  const allSpecs: [string, WarehouseIntrospectionMeasureField | WarehouseIntrospectionDimensionField][] = measureEntries.concat(
    Object.entries(output.dimensionsById) as any
  ) as any;

  allSpecs.forEach(([id, spec]) => {
    switch (spec.dataType) {
      case WarehouseDataTypeEnum.Boolean: {
        formatters[id] = value => (value ? "Yes" : "No");
        break;
      }
      case WarehouseDataTypeEnum.Currency: {
        formatters[id] = value => {
          return Dinero({ amount: round(value * 100) }).toFormat("$0,0.00");
        };
        break;
      }
      case WarehouseDataTypeEnum.DateTime: {
        formatters[id] = value => {
          const dt = isString(value) ? DateTime.fromISO(value) : DateTime.fromJSDate(value);
          return dt.toLocaleString();
        };
        break;
      }
      case WarehouseDataTypeEnum.Duration: {
        formatters[id] = value => Duration.fromObject({ seconds: value }).toISO();
        break;
      }
      case WarehouseDataTypeEnum.Number: {
        formatters[id] = value => String(round(value, 3));
        break;
      }
      case WarehouseDataTypeEnum.Percentage: {
        formatters[id] = value => `${round(value, 2)} %`;
        break;
      }
      case WarehouseDataTypeEnum.String: {
        formatters[id] = value => value;
        break;
      }
      case WarehouseDataTypeEnum.Weight: {
        formatters[id] = value => `${value} kgs`;
        break;
      }
      default: {
        throw `Unknown warehouse data type ${spec.dataType}`;
      }
    }
  });

  return formatters;
};