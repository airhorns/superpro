import { Table, TableBody, TableRow, TableHeader, TableFooter } from "grommet";
import { genericStyles } from "grommet/utils/styles";
import styled from "styled-components";
import { GrommetGlobalSize } from "./types";

export interface ExtraProps {
  size?: GrommetGlobalSize;
}

export const StyledDataTable = styled(Table)<ExtraProps>`
  border-spacing: 0;
  border-collapse: collapse;
  height: 100%;
  ${genericStyles};
`;

export const StyledDataTableRow = styled(TableRow)<ExtraProps>`
  ${props =>
    props.size &&
    `
    display: table;
    width: 100%;
    table-layout: fixed;
  `};
`;

export const StyledDataTableBody = styled(TableBody)<ExtraProps>`
  ${props =>
    props.size &&
    `
    display: block;
    width: 100%;
    max-height: ${props.theme.global.size[props.size]};
    overflow: auto;
  `};
`;

export const StyledDataTableHeader = styled(TableHeader)<ExtraProps>`
  ${props =>
    props.size &&
    `
    display: table;
    width: 100%;
    table-layout: fixed;
  `};
`;

export const StyledDataTableFooter = styled(TableFooter)<ExtraProps>`
  ${props =>
    props.size &&
    `
    display: table;
    width: 100%;
    table-layout: fixed;
  `};
`;
