import React from "react";
import memoizeOne from "memoize-one";
import { Box } from "grommet";
import { DateTime } from "luxon";
import { range } from "lodash";
import { LineIndexTuple } from "./BudgetFormSection";
import { SuperSheet, StyledDataGridHeader, StyledDataGridBody, StyledDataGridRow, StyledDataGridHeaderCell } from "superlib/supersheet";
import { SeriesLineSheetRow } from "./SeriesLinesSheetRow";
import { useSuperForm } from "superlib/superform";
import { BudgetFormValues } from "./BudgetForm";

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
          <StyledDataGridHeaderCell key="actions" width="118px" />
          <StyledDataGridHeaderCell key="description" primary width="244px">
            Description
          </StyledDataGridHeaderCell>
          {DefaultCellMonths().map(col => (
            <StyledDataGridHeaderCell key={col.toISO()} width="96px">
              {col.toFormat("MMM yyyy")}
            </StyledDataGridHeaderCell>
          ))}
        </StyledDataGridRow>
      </StyledDataGridHeader>
    );
  }
}

export const SeriesLinesSheet = (props: { lines: LineIndexTuple[]; children?: React.ReactNode }) => {
  const form = useSuperForm<BudgetFormValues>();
  let rowCount = 0;
  return (
    <Box overflow={{ horizontal: "auto" }} pad="small">
      <SuperSheet>
        <SheetHeader />
        <StyledDataGridBody>
          {props.lines.map(([line, lineIndex]) => {
            const result = <SeriesLineSheetRow key={line.id} line={line} linesIndex={lineIndex} rowIndex={rowCount} />;

            if (form.getValue(`budget.lines.${lineIndex}.value.scenariosEnabled`)) {
              rowCount += 3;
            } else {
              rowCount += 1;
            }

            return result;
          })}
          {props.children}
        </StyledDataGridBody>
      </SuperSheet>
    </Box>
  );
};
