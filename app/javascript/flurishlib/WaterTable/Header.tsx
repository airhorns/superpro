import _ from "lodash";
import React from "react";
import { Text, Box, Button, TableCell, BoxProps } from "grommet";
import { StyledDataTableHeader, StyledDataTableRow } from "./StyledDataTable";
import { WaterTableColumnSpec, WaterTableRecord, SortState, GrommetGlobalSize } from "./types";
import styled, { ThemeConsumer } from "styled-components";

const SorterButton = styled(Button)`
  flex-shrink: 1;
  height: 100%;
`;

const alignmentForColumn = <Record extends WaterTableRecord>(column: WaterTableColumnSpec<Record>): BoxProps["align"] => {
  switch (column.align) {
    case "center":
      return "center";
    case "right":
      return "end";
    default:
      return "start";
  }
};

export interface HeaderProps<Record extends WaterTableRecord> {
  columns: WaterTableColumnSpec<Record>[];
  onSort?: (column: WaterTableColumnSpec<Record>) => void;
  sortState?: SortState;
  size?: GrommetGlobalSize;
}

export class Header<Record extends WaterTableRecord> extends React.Component<HeaderProps<Record>> {
  render() {
    return (
      <ThemeConsumer>
        {theme => {
          const dataTableContextTheme = {
            ...theme.table.header,
            ...theme.dataTable.header
          } as any;

          return (
            <StyledDataTableHeader size={this.props.size}>
              <StyledDataTableRow>
                {this.props.columns.map(column => {
                  let icon: React.ReactNode = null;

                  if (this.props.sortState && this.props.sortState.columnKey === column.sortKey) {
                    const Icon = theme.dataTable.icons[this.props.sortState.ascending ? "ascending" : "descending"];
                    icon = <Icon />;
                  }

                  let content = (
                    <Box align={alignmentForColumn(column)} direction="row" {..._.omit(dataTableContextTheme, ["background", "border"])}>
                      {icon}
                      {_.isString(column.header) ? <Text weight="bold">{column.header}</Text> : column.header}
                    </Box>
                  );

                  if (column.sortable && this.props.onSort) {
                    content = (
                      <SorterButton fill={true} hoverIndicator onClick={() => this.props.onSort && this.props.onSort(column)}>
                        {content}
                      </SorterButton>
                    );
                  }

                  return (
                    <TableCell key={column.key} scope="col" style={{ position: "relative" }}>
                      {content}
                    </TableCell>
                  );
                })}
              </StyledDataTableRow>
            </StyledDataTableHeader>
          );
        }}
      </ThemeConsumer>
    );
  }
}
