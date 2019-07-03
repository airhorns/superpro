import React from "react";
import { StyledDataGrid, StyledDataGridContainer } from "./StyledDataGrid";
import EventEmitter from "eventemitter3";
import { SheetKeys } from "./SheetKeys";
import { SheetSelection, Coordinates, moveCoordinates, clampCoordinates } from "./Selection";

export type SheetUpdateCallback = (event: { version: number }) => void;
export const SheetContext = React.createContext<Sheet>(null as any);

export const useSheet = () => {
  const sheet = React.useContext(SheetContext);

  if (!sheet) {
    throw new Error("Can't use sheet components outside a <Sheet/> wrapper");
  }

  return sheet;
};

export const useCell = <E extends HTMLElement>(row: number, column: number, ref: React.MutableRefObject<E | null>) => {
  const sheet = useSheet();
  const [sheetVersion, setSheetVersion] = React.useState<number>(0);

  React.useEffect(() => {
    const sheetUpdated: SheetUpdateCallback = (event: { version: number }) => {
      setSheetVersion(event.version);
    };

    sheet.registerCell(row, column, ref, sheetUpdated);

    return () => {
      sheet.unregisterCell(row, column, sheetUpdated);
    };
  });

  return {
    sheet,
    sheetVersion,
    editing: sheet.isEditing(row, column),
    selected: sheet.isSelected(row, column)
  };
};

interface SheetState {
  selection: null | SheetSelection;
  edit: null | Coordinates;
  version: number;
}

export class Sheet extends React.Component<{}, SheetState> {
  state: SheetState = { selection: null, edit: null, version: 0 };
  updates = new EventEmitter();
  cells: Map<number, Map<number, React.MutableRefObject<any>>> = new Map();
  rowNumbers = new Set<number>();
  columnNumbers = new Set<number>();
  containerRef: React.RefObject<HTMLDivElement> = React.createRef();

  isSelected(row: number, column: number) {
    const selection = this.state.selection;
    if (!selection) return false;
    return selection.start.row <= row && selection.start.column <= column && selection.end.row >= row && selection.end.column >= column;
  }

  isEditing(row: number, column: number) {
    if (!this.state.edit) return false;
    return this.state.edit.row == row && this.state.edit.column == column;
  }

  handleKeyDown = (event: React.KeyboardEvent) => {
    const action = Object.entries(SheetKeys).find(([_name, action]) => {
      if (this.state.edit && !action.availableDuringEdit) {
        return false;
      }
      return action.check(event as any);
    });

    if (action) {
      console.debug("sheet event: keyDown", action);
      action[1].action(this);
      event.preventDefault();
    }
  };

  handleCellClick(row: number, column: number) {
    console.debug("sheet event: cellClick", row, column);
    this.focusContainer();
    if (!this.isEditing(row, column)) {
      const coord = { row, column };
      return this.moveSelectionTo(coord, coord);
    }
  }

  handleCellDoubleClick(row: number, column: number) {
    console.debug("sheet event: cellDoubleClick", row, column);
    this.focusContainer();
    const coord = { row, column };
    return this.moveSelectionTo(coord, coord).startEdit();
  }

  startEdit() {
    if (this.state.selection) {
      this.update({ edit: { row: this.state.selection.start.row, column: this.state.selection.start.column } });
    }
  }

  toggleEdit(row: number, column: number) {
    if (this.isEditing(row, column)) {
      this.cancelEdit();
    } else {
      const coord = { row, column };
      this.moveSelectionTo(coord, coord).startEdit();
    }
  }

  cancelEdit() {
    this.update({ edit: null }).focusContainer();
  }

  collapseSelection() {
    if (this.state.selection) {
      return this.update({ selection: { start: this.state.selection.start, end: this.state.selection.start } });
    }
    return this;
  }

  moveSelectionTo(start: Coordinates, end: Coordinates) {
    const rowMin = Math.min(...Array.from(this.rowNumbers));
    const rowMax = Math.max(...Array.from(this.rowNumbers));
    const colMin = Math.min(...Array.from(this.columnNumbers));
    const colMax = Math.max(...Array.from(this.columnNumbers));

    return this.focusContainer().update(
      {
        selection: {
          start: clampCoordinates(start, rowMin, rowMax, colMin, colMax),
          end: clampCoordinates(end, rowMin, rowMax, colMin, colMax)
        },
        edit: null
      },
      () => {
        const cellRef = this.getSelectedCellRef();
        if (cellRef && cellRef.current) {
          cellRef.current.scrollIntoView({ inline: "center" });
        }
      }
    );
  }

  moveSelectionDelta(rowDelta: number, columnDelta: number) {
    if (this.state.selection) {
      return this.moveSelectionTo(
        moveCoordinates(this.state.selection.start, rowDelta, columnDelta),
        moveCoordinates(this.state.selection.end, rowDelta, columnDelta)
      );
    }
    return this;
  }

  registerCell(row: number, column: number, ref: React.MutableRefObject<any>, updateCallback: SheetUpdateCallback) {
    this.updates.on("update", updateCallback);
    let cellRow = this.cells.get(row);
    if (!cellRow) {
      cellRow = new Map<number, React.MutableRefObject<any>>();
      this.cells.set(row, cellRow);
    }
    cellRow.set(column, ref);

    this.rowNumbers.add(row);
    this.columnNumbers.add(column);
  }

  unregisterCell(row: number, column: number, updateCallback: SheetUpdateCallback) {
    this.updates.off("update", updateCallback);
    let cellRow = this.cells.get(row);
    if (cellRow) {
      cellRow.delete(column);
    }
    this.rowNumbers.delete(row);
    this.columnNumbers.delete(column);
  }

  getSelectedCellRef() {
    if (!this.state.selection) return;
    const cellRow = this.cells.get(this.state.selection.start.row);
    if (cellRow) {
      return cellRow.get(this.state.selection.start.column);
    }
  }

  onCellBlur = () => {
    this.focusContainer();
  };

  focusContainer() {
    this.containerRef.current && this.containerRef.current.focus();
    return this;
  }

  update<K extends keyof SheetState>(update: Pick<SheetState, K>, callback?: () => void) {
    this.setState({ ...update, version: this.state.version + 1 } as any, () => {
      this.updates.emit("update", { version: this.state.version });
      callback && callback();
    });
    return this;
  }

  render() {
    return (
      <StyledDataGridContainer tabIndex={0} ref={this.containerRef} onKeyDown={this.handleKeyDown}>
        <SheetContext.Provider value={this}>
          <StyledDataGrid onKeyDown={this.handleKeyDown}>{this.props.children}</StyledDataGrid>
        </SheetContext.Provider>
      </StyledDataGridContainer>
    );
  }
}
