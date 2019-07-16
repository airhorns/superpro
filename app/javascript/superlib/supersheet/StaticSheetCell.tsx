import React from "react";
import { StyledDataGridCell } from "./StyledDataGrid";

export const StaticSheetCell = (props: { children: React.ReactNode }) => {
  return <StyledDataGridCell>{props.children}</StyledDataGridCell>;
};
