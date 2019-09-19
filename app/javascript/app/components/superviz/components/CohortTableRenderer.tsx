import React from "react";
import { range, groupBy, keyBy, round } from "lodash";
import { Box } from "grommet";
import { DateTime } from "luxon";
import { interpolateOranges } from "d3-scale-chromatic";
import { WaterTable, WaterTableColumnSpec } from "superlib/WaterTable";
import { SuccessfulWarehouseQueryResult } from "./GetWarehouseData";
import { Document, VizBlock, VizSystem } from "../schema";
import { assert } from "superlib";

interface CohortRecord {
  key: string;
  [key: string]: any;
}

const cohortRange = range(0, 12);

const cohortPivot = (result: SuccessfulWarehouseQueryResult, system: VizSystem) => {
  return Object.entries(groupBy(result.records, system.extra.cohortId)).map(([cohortId, recordGroup]) => {
    const pivotedRecord: CohortRecord = {
      key: cohortId,
      [system.extra.cohortId]: DateTime.fromISO(cohortId)
    };
    const recordsByMonth = keyBy(recordGroup, system.xId);

    cohortRange.forEach(month => {
      let val = 0;
      if (recordsByMonth[month]) {
        val = recordsByMonth[month][system.yId];
      }

      pivotedRecord[month] = val;
    });

    return pivotedRecord;
  });
};

export const CohortTableRenderer = (props: { result: SuccessfulWarehouseQueryResult; doc: Document; block: VizBlock }) => {
  const system = assert(props.block.viz.systems[0]);
  const columns: WaterTableColumnSpec<CohortRecord>[] = [
    {
      key: "cohort_title",
      render: (record: CohortRecord) => record[system.extra.cohortId].toFormat("MMMM y"),
      header: "Cohort",
      sortable: false
    },
    ...cohortRange.map(month => ({
      key: String(month),
      render: (record: CohortRecord) => round(record[month], 2) + "%",
      cellStyle: (record: CohortRecord) => ({ backgroundColor: interpolateOranges((record[month] / 100) * 0.8) }),
      header: String(month),
      sortable: false
    }))
  ];

  return (
    <Box>
      <WaterTable columns={columns} records={cohortPivot(props.result, system)} />
    </Box>
  );
};
