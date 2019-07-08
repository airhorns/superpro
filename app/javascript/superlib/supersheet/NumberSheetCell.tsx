import React from "react";
import { StyledDataGridCell } from "./StyledDataGrid";
import { useCell } from "./SuperSheet";
import { NumberInputProps, NumberInput } from "flurishlib/superform";

export interface NumberSheetCellProps extends NumberInputProps {
  row: number;
  column: number;
}

export const NumberSheetCell = (props: NumberSheetCellProps) => {
  const ref = React.useRef<HTMLTableDataCellElement>(null);
  const { sheet, editing, selected } = useCell({ row: props.row, column: props.column, path: props.path, ref });

  return (
    <StyledDataGridCell
      ref={ref}
      editing={editing}
      selected={selected}
      onClick={() => sheet.handleCellClick(props.row, props.column)}
      onDoubleClick={() => sheet.handleCellDoubleClick(props.row, props.column)}
    >
      <NumberInput
        plain={editing ? true : undefined}
        autoFocus={editing}
        style={{ padding: "0px" }}
        displayType={editing ? "input" : "text"}
        {...props}
      />
    </StyledDataGridCell>
  );
};
