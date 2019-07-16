import React from "react";
import { StyledDataGridCell, DataGridCellProps } from "./StyledDataGrid";
import { useCell } from "./SuperSheet";
import { NumberInputProps, NumberInput } from "superlib/superform";
import { propsForInnerCellComponent } from "./utils";

export interface NumberSheetCellProps extends NumberInputProps {
  row: number;
  column: number;
  rowSpan?: number;
  colSpan?: number;
  as?: React.ComponentType<DataGridCellProps>;
}

export const NumberSheetCell = (props: NumberSheetCellProps) => {
  const ref = React.useRef<HTMLTableDataCellElement>(null);
  const { sheet, editing, selected, form } = useCell({
    row: props.row,
    column: props.column,
    path: props.path,
    rowSpan: props.rowSpan,
    colSpan: props.colSpan,
    ref,
    handleKeyDown(event) {
      if (event.key.match(/^[0-9]$/)) {
        form.setValue(props.path, "");
        sheet.startEdit();
      }
    }
  });
  const Component = props.as || StyledDataGridCell;

  return (
    <Component
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
        {...propsForInnerCellComponent(props)}
      />
    </Component>
  );
};
