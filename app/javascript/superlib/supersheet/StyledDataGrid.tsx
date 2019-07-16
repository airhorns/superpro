import { genericStyles } from "grommet/utils/styles";
import { normalizeColor } from "grommet/utils/colors";
import styled, { css } from "styled-components";

export const StyledDataGridContainer = styled.div`
  :focus {
    outline: none;
  }
  overflow-x: auto;
`;

export const focusStyle = css`
  z-index: 1;
  border-color: ${props => normalizeColor(props.theme.global.focus.border.color, props.theme)};
  box-shadow: 0 0 1px 1px ${props => normalizeColor(props.theme.global.focus.border.color, props.theme)};
  ::-moz-focus-inner {
    border: 0;
  }
`;

export const editingStyle = css`
  z-index: 1;
  border-color: ${props => props.theme.global.colors["brand"]};
  box-shadow: 0 0 2px 2px ${props => props.theme.global.colors["brand"]};
  ::-moz-focus-inner {
    border: 0;
  }
`;

// This is the styling for the data grid table that is compatible with react-beautiful-dnd, which needs rows that it
// can mess around with the styling of to not change their layout. We use the simplest and baddest strategy for this
// which is fixed table cell widths. See https://github.com/atlassian/react-beautiful-dnd/blob/master/docs/patterns/tables.md
export const StyledDataGrid = styled.table`
  border-collapse: collapse;
  table-layout: fixed;
  width: 100%;
  white-space: nowrap;
  margin-bottom: 16px;
  ${genericStyles};
`;

export const StyledDataGridRow = styled.tr<{ dragging?: boolean }>`
  min-height: 48px;
  ${props => props.dragging && `background: ${props.theme.global.colors["light-3"]};`}
`;

export const StyledDataGridBody = styled.tbody`
  border: 0;
`;

export const StyledDataGridHeader = styled.thead`
  border: 0;
`;

export const StyledDataGridHeaderCell = styled.th<{ primary?: boolean; fixedWidth: string | number }>`
  box-sizing: border-box;
  border-bottom: 1px solid ${props => props.theme.global.colors["dark-2"]};
  font-weight: ${props => (props.primary ? "bold" : "normal")};
  width: ${props => props.fixedWidth};
`;

export interface DataGridCellProps {
  editing?: boolean;
  selected?: boolean;
}

export const StyledDataGridCell = styled.td<DataGridCellProps>`
  box-sizing: border-box;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  ${props => `border: 1px solid ${props.theme.global.colors["light-1"]};`}
  ${props => (props.editing ? editingStyle : props.selected ? focusStyle : false)}
`;

export const StyledDataGridMultiCell = styled.td<{ width: string | number }>`
  width: ${props => props.width};
`;

export const StyledDataGridFakeCell = styled.div<DataGridCellProps>`
  box-sizing: border-box;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  min-height: 48px;
  ${props => `border: 1px solid ${props.theme.global.colors["light-1"]};`}
  ${props => (props.editing ? editingStyle : props.selected ? focusStyle : false)}
`;
