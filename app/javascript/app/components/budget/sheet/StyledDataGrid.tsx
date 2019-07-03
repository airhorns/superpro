import { genericStyles } from "grommet/utils/styles";
import { normalizeColor } from "grommet/utils/colors";
import styled, { css } from "styled-components";

export const StyledDataGridContainer = styled.div`
  :focus {
    outline: none;
  }
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

// This is an implementation of table layout using CSS grid, adapted from here:
// https://adamlynch.com/flexible-data-tables-with-css-grid/?1
// It's handy because
export const StyledDataGrid = styled.table`
  display: grid;
  border-collapse: collapse;
  min-width: 100%;
  grid-template-columns:
    48px
    288px
    repeat(12, 96px)
    48px;

  grid-template-rows: 32px;
  grid-auto-rows: 48px;
  align-items: stretch;
  ${genericStyles};
`;

export const StyledDataGridRow = styled.tr`
  display: contents;
`;

export const StyledDataGridBody = styled.tbody`
  display: contents;
`;

export const StyledDataGridHeader = styled.thead`
  display: contents;
`;

export const StyledDataGridHeaderCell = styled.th`
  border-bottom: 2px solid ${props => props.theme.global.colors["dark-2"]};
`;

export const StyledDataGridCell = styled.td<{ editing?: boolean; selected?: boolean }>`
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  ${props => `border: 1px solid ${props.theme.global.colors["light-1"]};`}
  ${props => (props.editing ? editingStyle : props.selected ? focusStyle : false)}

  display: flex;
  align-items: center;
`;
