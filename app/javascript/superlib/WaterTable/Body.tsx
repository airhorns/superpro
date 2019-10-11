import { isUndefined } from "lodash";
import React from "react";
import { StyledDataTableBody, StyledDataTableRow } from "./StyledDataTable";
import { WaterTableColumnSpec, WaterTableRecord, GrommetGlobalSize } from "./types";
import { TableCell } from "grommet";

export interface BodyProps<Record extends WaterTableRecord> {
  columns: WaterTableColumnSpec<Record>[];
  records: Record[];
  size?: GrommetGlobalSize;
  emptyContent?: () => React.ReactNode;
}

export class Body<Record extends WaterTableRecord> extends React.Component<BodyProps<Record>> {
  render() {
    return (
      <StyledDataTableBody size={this.props.size}>
        {this.props.records.map((record, index) => (
          <StyledDataTableRow key={isUndefined(record.key) ? `index-${index}` : `record-${record.key}`} size={this.props.size}>
            {this.props.columns.map(column => {
              const content = column.render(record, index);
              const cellStyle: React.CSSProperties = { position: "relative" };
              if (column.cellStyle) {
                Object.assign(cellStyle, column.cellStyle(record, index));
              }

              return (
                <TableCell key={column.key} align={column.align} scope={column.primary ? "row" : undefined} style={cellStyle}>
                  {content}
                </TableCell>
              );
            })}
          </StyledDataTableRow>
        ))}
        {this.props.records.length == 0 && (
          <StyledDataTableRow key="empty-content">
            <TableCell colSpan={this.props.columns.length}>{this.props.emptyContent && this.props.emptyContent()}</TableCell>
          </StyledDataTableRow>
        )}
      </StyledDataTableBody>
    );
  }
}
