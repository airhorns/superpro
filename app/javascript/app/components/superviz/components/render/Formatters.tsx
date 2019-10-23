import Dinero from "dinero.js";
import { DateTime, Duration } from "luxon";
import { round, isNumber } from "lodash";
import { OutputIntrospection } from "../GetWarehouseData";
import { WarehouseDataTypeEnum, WarehouseOutputIntrospectionMeasure, WarehouseOutputIntrospectionDimension } from "app/app-graph";
import { isDate } from "util";

export type FormatterFns = {
  [id: string]: (value: any) => string;
};

export const formattersForOutput = (output: OutputIntrospection): FormatterFns => {
  const formatters: FormatterFns = {};
  const measureEntries = Object.entries(output.measuresById).concat(Object.entries(output.pivotedMeasuresById));
  const allSpecs: [string, WarehouseOutputIntrospectionMeasure | WarehouseOutputIntrospectionDimension][] = measureEntries.concat(
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
          let dt: DateTime;
          if (isNumber(value)) {
            dt = DateTime.fromMillis(value);
          } else if (isDate(value)) {
            dt = DateTime.fromJSDate(value);
          } else {
            dt = DateTime.fromISO(value);
          }

          switch (spec.operator) {
            case "date_trunc_year":
            case "date_trunc_month":
            case "date_trunc_week":
            case "date_trunc_day": {
              // when these dates are truncated, the local offset can move the date past the boundary that really matters
              // truncated dates like 2016-01-01T00:00:00.000+00:00 when presented in local time are in 2015, which looks dumb
              // strip the zone and then return the format that makes sense for the operator at hand
              const shifted = dt.setZone("utc");
              switch (spec.operator) {
                case "date_trunc_year": {
                  return shifted.toFormat("yyyy");
                }
                case "date_trunc_month": {
                  return shifted.toFormat("LLLL yyyy");
                }
                case "date_trunc_week": {
                  return shifted.toFormat("'Week of' DD");
                }
                default: {
                  return shifted.toLocaleString();
                }
              }
            }

            default: {
              return dt.toLocaleString();
            }
          }
        };
        break;
      }
      case WarehouseDataTypeEnum.Duration: {
        formatters[id] = value => {
          const duration = Duration.fromObject({ seconds: value });
          if (duration.years > 0) {
            return duration.toFormat("Y 'years,' M 'months,' d 'days'");
          } else if (duration.months > 0) {
            return duration.toFormat("M 'months,' d 'days'");
          } else if (duration.days > 0) {
            return duration.toFormat("d 'days,' h 'hours'");
          } else if (duration.hours > 0) {
            return duration.toFormat("h 'hours,' m 'minutes,' s 'seconds'");
          } else if (duration.minutes > 0) {
            return duration.toFormat("m 'minutes,' s 'seconds'");
          } else {
            return String(round(duration.shiftTo("seconds").seconds, 3)) + " secs";
          }
        };
        break;
      }
      case WarehouseDataTypeEnum.Number: {
        formatters[id] = value => String(round(value, 3));
        break;
      }
      case WarehouseDataTypeEnum.Percentage: {
        formatters[id] = value => `${round(value * 100, 2)} %`;
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
