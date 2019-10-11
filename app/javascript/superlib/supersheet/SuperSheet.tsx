import React from "react";
import { StyledDataGrid, StyledDataGridContainer } from "./StyledDataGrid";
import EventEmitter from "eventemitter3";
import { SheetKeys, isUnknownHotkey } from "./SheetKeys";
import { SheetSelection, Coordinates, moveCoordinates, clampCoordinates } from "./Selection";
import { useSuperForm } from "superlib/superform";

export type SheetUpdateCallback = (event: { version: number }) => void;
export const SheetContext = React.createContext<SuperSheet>(null as any);

export const useSheet = () => {
  const sheet = React.useContext(SheetContext);

  if (!sheet) {
    throw new Error("Can't use sheet components outside a <Sheet/> wrapper");
  }

  return sheet;
};

export const useCell = <E extends HTMLElement>(registration: CellRegistration) => {
  const sheet = useSheet();
  const form = useSuperForm<any>();
  const [sheetVersion, setSheetVersion] = React.useState<number>(0);

  React.useEffect(() => {
    const sheetUpdated: SheetUpdateCallback = (event: { version: number }) => {
      setSheetVersion(event.version);
    };

    sheet.registerCell(registration, sheetUpdated);

    return () => {
      sheet.unregisterCell(registration, sheetUpdated);
    };
  });

  return {
    sheet,
    sheetVersion,
    form,
    editing: sheet.isEditing(registration.row, registration.column),
    selected: sheet.isSelected(registration.row, registration.column)
  };
};

interface CellRegistration {
  ref: React.MutableRefObject<any>;
  path: string | string[];
  row: number;
  column: number;
  handleKeyDown: (event: KeyboardEvent) => void;
}

interface SheetState {
  selection: null | SheetSelection;
  edit: null | Coordinates;
  version: number;
}

export class SuperSheet extends React.Component<{}, SheetState> {
  state: SheetState = { selection: null, edit: null, version: 0 };
  updates = new EventEmitter();
  cells: Map<number, Map<number, CellRegistration>> = new Map();
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

    // If the key pressed is not a keyboard shortcut and is a letter, number, or puncutation mark
    // it's intended for the data in the cell. Set the value of the form to that data.
    if (!this.state.edit && this.state.selection && !isUnknownHotkey(event as any)) {
      console.debug("sheet event: keyDown, edit passthrough", event);
      const registration = this.getSelectedCellRegistration();
      if (registration) {
        registration.handleKeyDown(event as any);
      }
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

  handleContainerBlur = (event: React.FocusEvent) => {
    // If the container is being blurred, it could be because the user has clicked into some other interactive element, in which case the sheet should lose its selection. Sadly, the container blur event fires when the container loses focus to one of the inputs *inside* it also. This is because the focus has gotten more specific to be on one textinput in one cell. In this case, we don't want the sheet to lose its selection. event.relatedTarget points to the node which has taken focus, so if that node is inside the container, don't do anything. If it's outside the container, reset the focus.
    if (this.containerRef.current && event.relatedTarget) {
      if (this.containerRef.current.contains(event.relatedTarget as any)) {
        return;
      } else {
        this.clearSelection();
      }
    }
  };
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

  clearSelection() {
    if (this.state.selection) {
      return this.update({ selection: null });
    }
    return this;
  }

  collapseSelection() {
    if (this.state.selection) {
      return this.update({ selection: { start: this.state.selection.start, end: this.state.selection.start } });
    }
    return this;
  }

  moveSelectionTo(start: Coordinates, end: Coordinates) {
    const { rowMin, rowMax, colMin, colMax } = this.dimensions();

    return this.focusContainer().update(
      {
        selection: {
          start: clampCoordinates(start, rowMin, rowMax, colMin, colMax),
          end: clampCoordinates(end, rowMin, rowMax, colMin, colMax)
        },
        edit: null
      },
      () => {
        const registration = this.getSelectedCellRegistration();
        if (registration && registration.ref.current) {
          registration.ref.current.scrollIntoView({ inline: "center" });
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

  dimensions() {
    const rowMin = Math.min(...Array.from(this.cells.keys()));
    const rowMax = Math.max(...Array.from(this.cells.keys()));
    const firstRow = this.cells.get(0);
    let colMin;
    let colMax;
    if (firstRow) {
      colMin = Math.min(...Array.from(firstRow.keys()));
      colMax = Math.max(...Array.from(firstRow.keys()));
    } else {
      colMin = 0;
      colMax = 0;
    }

    return {
      rowMin,
      rowMax,
      colMin,
      colMax
    };
  }

  registerCell(registration: CellRegistration, updateCallback: SheetUpdateCallback) {
    this.updates.on("update", updateCallback);
    let cellRow = this.cells.get(registration.row);
    if (!cellRow) {
      cellRow = new Map<number, CellRegistration>();
      this.cells.set(registration.row, cellRow);
    }
    cellRow.set(registration.column, registration);
  }

  unregisterCell(registration: CellRegistration, updateCallback: SheetUpdateCallback) {
    this.updates.off("update", updateCallback);
    const cellRow = this.cells.get(registration.row);
    if (cellRow) {
      cellRow.delete(registration.column);
    }
  }

  getSelectedCellRegistration() {
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
      <StyledDataGridContainer tabIndex={0} ref={this.containerRef} onKeyDown={this.handleKeyDown} onBlur={this.handleContainerBlur}>
        <SheetContext.Provider value={this}>
          <StyledDataGrid onKeyDown={this.handleKeyDown}>{this.props.children}</StyledDataGrid>
        </SheetContext.Provider>
      </StyledDataGridContainer>
    );
  }
}
