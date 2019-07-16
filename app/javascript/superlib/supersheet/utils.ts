import { omit } from "lodash";

export const propsForInnerCellComponent = <T extends { [key: string]: any }>(props: T) =>
  omit(props, ["as", "row", "column", "rowSpan", "colSpan", "ref"]);
