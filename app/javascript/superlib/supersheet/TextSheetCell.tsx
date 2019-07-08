import React from "react";
import { Text } from "grommet";
import { StyledDataGridCell } from "./StyledDataGrid";
import { useCell } from "./SuperSheet";
import { Input, InputProps } from "flurishlib/superform";
import { isUndefined } from "lodash";

export interface TextSheetCellProps extends InputProps {
  row: number;
  column: number;
}

export const TextSheetCell = (props: TextSheetCellProps) => {
  const ref = React.useRef<HTMLTableDataCellElement>(null);
  const { sheet, form, editing, selected } = useCell({ row: props.row, column: props.column, path: props.path, ref });
  const value = form.getValue(props.path);

  return (
    <StyledDataGridCell
      ref={ref}
      editing={editing}
      selected={selected}
      onClick={() => sheet.handleCellClick(props.row, props.column)}
      onDoubleClick={() => sheet.handleCellDoubleClick(props.row, props.column)}
    >
      {editing && <Input autoFocus plain path={props.path} onBlur={sheet.onCellBlur} {...props} />}
      {!editing && !isUndefined(value) && <Text>{value}</Text>}
      {!editing && isUndefined(value) && <Text color="status-unknown">{props.placeholder}</Text>}
    </StyledDataGridCell>
  );
};
