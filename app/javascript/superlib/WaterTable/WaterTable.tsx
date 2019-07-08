import React from "react";
import { omit } from "lodash";
import { Header } from "./Header";
import { Body } from "./Body";
import { StyledDataTable } from "./StyledDataTable";
import { WaterTableRecord, WaterTableColumnSpec, SortState, GrommetSize } from "./types";
import { Omit } from "type-zoo/types";

type TableProps = Omit<JSX.IntrinsicElements["table"], "ref">;

export interface WaterTableProps<Record extends WaterTableRecord> extends TableProps {
  alignSelf?: "start" | "center" | "end" | "stretch";
  gridArea?: string;
  margin?:
    | GrommetSize
    | {
        bottom?: GrommetSize;
        left?: GrommetSize;
        right?: GrommetSize;
        top?: GrommetSize;
      };
  columns: WaterTableColumnSpec<Record>[];
  records: Record[];
  sortState?: SortState;
  handleSort?: (sortState?: SortState) => void;
  size?: "small" | "medium" | "large" | "xlarge";
  emptyContent?: () => React.ReactNode;
  ref?: React.RefObject<HTMLTableElement>;
}

export const WaterTable = class WaterTable<Record extends WaterTableRecord> extends React.Component<WaterTableProps<Record>> {
  handleSort = (column: WaterTableColumnSpec<Record>) => {
    let newSort: SortState | undefined;
    if (column.sortKey) {
      newSort = { columnKey: column.sortKey, ascending: false };

      if (this.props.sortState && this.props.sortState.columnKey == newSort.columnKey) {
        newSort.ascending = !this.props.sortState.ascending;
      }
    }

    this.props.handleSort && this.props.handleSort(newSort);
  };

  render() {
    return (
      <StyledDataTable {...omit(this.props, ["alignSelf", "gridArea", "margin", "columns", "records", "size", "theme", "children"])}>
        <Header columns={this.props.columns} size={this.props.size} sortState={this.props.sortState} onSort={this.handleSort} />
        <Body columns={this.props.columns} records={this.props.records} size={this.props.size} emptyContent={this.props.emptyContent} />
      </StyledDataTable>
    );
  }
};
