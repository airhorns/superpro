import React from "react";
import { base } from "grommet/themes";

export interface SortState {
  columnKey: string;
  ascending: boolean;
}

export interface WaterTableRecord {
  key: string;
  [key: string]: any;
}

export interface WaterTableColumnSpec<Record extends WaterTableRecord> {
  key: string;
  render: (record: Record, index: number) => any;
  primary?: boolean;
  align?: "center" | "left" | "right";
  header?: React.ReactNode;
  searchable?: boolean;
  sortable?: boolean;
  sortKey?: string;
}

export type GrommetSize = "none" | "xxsmall" | "xsmall" | "small" | "medium" | "large" | "xlarge" | string;
export type GrommetGlobalSize = keyof (typeof base)["global"]["size"];
