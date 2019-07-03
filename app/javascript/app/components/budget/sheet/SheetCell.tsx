import React from "react";
import { StyledDataGridCell } from "./StyledDataGrid";
import { useCell, Sheet } from "./Sheet";

export interface SheetCellRenderProps {
  editing: boolean;
  selected: boolean;
  sheet: Sheet;
  inputProps: {
    onBlur: () => void;
  };
}

export const SheetCell = (props: { row: number; column: number; children: (details: SheetCellRenderProps) => React.ReactNode }) => {
  const ref = React.useRef<HTMLTableDataCellElement>(null);
  const { sheet, editing, selected } = useCell(props.row, props.column, ref);
  return (
    <StyledDataGridCell
      ref={ref}
      editing={editing}
      selected={selected}
      onClick={() => sheet.handleCellClick(props.row, props.column)}
      onDoubleClick={() => sheet.handleCellDoubleClick(props.row, props.column)}
    >
      {props.children({ editing, selected, sheet, inputProps: { onBlur: sheet.onCellBlur } })}
    </StyledDataGridCell>
  );
};
