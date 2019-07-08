import React from "react";
import memoizeOne from "memoize-one";
import { Box } from "grommet";
import { DateTime } from "luxon";
import { range } from "lodash";
import { LineIndexTuple } from "./BudgetFormSection";
import { SuperSheet, StyledDataGridHeader, StyledDataGridBody, StyledDataGridRow, StyledDataGridHeaderCell } from "flurishlib/supersheet";
import { SeriesLineSheetRow } from "./SeriesLinesSheetRow";

export const DefaultCellMonths = memoizeOne(() => {
  const now = DateTime.local();
  const currentYear = now.year;
  const currentMonth = now.month;
  return range(0, 12).map(i => DateTime.local(currentYear, currentMonth, 1).plus({ months: i }));
});

class SheetHeader extends React.PureComponent<{}> {
  render() {
    return (
      <StyledDataGridHeader>
        <StyledDataGridRow>
          <StyledDataGridHeaderCell key="draghandle" />
          <StyledDataGridHeaderCell key="description" primary>
            Description
          </StyledDataGridHeaderCell>
          {DefaultCellMonths().map(col => (
            <StyledDataGridHeaderCell key={col.toISO()}>{col.toFormat("MMM yyyy")}</StyledDataGridHeaderCell>
          ))}
          <StyledDataGridHeaderCell key="actions" />
        </StyledDataGridRow>
      </StyledDataGridHeader>
    );
  }
}

export const SeriesLinesSheet = (props: { lines: LineIndexTuple[]; children?: React.ReactNode }) => (
  <Box overflow={{ horizontal: "auto" }} pad="small">
    <SuperSheet>
      <SheetHeader />
      <StyledDataGridBody>
        {props.lines.map(([line, lineIndex], rowIndex) => (
          <SeriesLineSheetRow key={line.id} line={line} linesIndex={lineIndex} rowIndex={rowIndex} />
        ))}
        {props.children}
      </StyledDataGridBody>
    </SuperSheet>
  </Box>
);
