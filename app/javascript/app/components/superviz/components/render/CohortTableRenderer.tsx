import React from "react";
import { range, groupBy, keyBy, isUndefined, compact } from "lodash";
import { DateTime } from "luxon";
import { scaleLinear } from "d3-scale";
import { interpolateOranges } from "d3-scale-chromatic";
import { WaterTable, WaterTableColumnSpec } from "superlib/WaterTable";
import { SuccessfulWarehouseQueryResult } from "../GetWarehouseData";
import { ReportDocument, VizBlock, VizSystem } from "../../schema";
import { assert } from "superlib";

interface CohortRecord {
  key: string;
  [key: string]: any;
}

const cohortRange = range(0, 12);

const colorScaleForField = (system: VizSystem, result: SuccessfulWarehouseQueryResult) => {
  const cohortId = assert(system.xId);

  const values = compact(
    result.records.map(record => {
      if (record[cohortId] != 0) {
        return record[system.yId];
      }
    })
  );
  const domain = [Math.min(...values) || 0, Math.max(...values) || 1];

  return scaleLinear()
    .domain(domain)
    .range([0, 0.8]);
};

const cohortPivot = (result: SuccessfulWarehouseQueryResult, system: VizSystem) => {
  return Object.entries(groupBy(result.records, record => record[system.extra.cohortId].toISOString())).map(([cohortId, recordGroup]) => {
    const pivotedRecord: CohortRecord = {
      key: cohortId,
      [system.extra.cohortId]: DateTime.fromISO(cohortId)
    };
    const recordsByMonth = keyBy(recordGroup, system.xId);

    cohortRange.forEach(month => {
      if (recordsByMonth[month]) {
        pivotedRecord[month] = recordsByMonth[month][system.yId];
      }
    });

    return pivotedRecord;
  });
};

export const CohortTableRenderer = (props: { result: SuccessfulWarehouseQueryResult; doc: ReportDocument; block: VizBlock }) => {
  const system = assert(props.block.viz.systems[0]);
  const colorScale = colorScaleForField(system, props.result);
  const columns: WaterTableColumnSpec<CohortRecord>[] = [
    {
      key: "cohort_title",
      render: (record: CohortRecord) => record[system.extra.cohortId].toFormat("MMMM y"),
      header: "Cohort",
      sortable: false
    },
    ...cohortRange.map(month => ({
      key: String(month),
      render: (record: CohortRecord) => {
        if (!isUndefined(record[month])) {
          return props.result.formatters[system.yId](record[month]);
        } else {
          return <></>;
        }
      },
      cellStyle: (record: CohortRecord) => {
        if (month != 0 && !isUndefined(record[month])) {
          return { backgroundColor: interpolateOranges(colorScale(record[month])) };
        } else {
          return {};
        }
      },
      header: String(month),
      sortable: false
    }))
  ];

  return <WaterTable columns={columns} records={cohortPivot(props.result, system)} />;
};
