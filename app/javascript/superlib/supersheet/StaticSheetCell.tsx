import React from "react";
import { StyledDataGridCell } from "./StyledDataGrid";

export const StaticSheetCell = (props: { width: string | number; children: React.ReactNode }) => {
  return <StyledDataGridCell width={props.width}>{props.children}</StyledDataGridCell>;
};
