import { clamp } from "lodash";

export interface Coordinates {
  row: number;
  column: number;
}

export interface SheetSelection {
  anchor: Coordinates;
  focus: Coordinates;
}

export const moveCoordinates = (coord: Coordinates, rowDelta: number, columnDelta: number) => {
  return {
    row: coord.row + rowDelta,
    column: coord.column + columnDelta
  };
};

export const clampCoordinates = (coord: Coordinates, minRow: number, maxRow: number, minColumn: number, maxColumn: number) => {
  return {
    row: clamp(coord.row, minRow, maxRow),
    column: clamp(coord.column, minColumn, maxColumn)
  };
};
