import React from "react";
import { range } from "lodash";
import EventEmitter from "eventemitter3";
import { SheetSelection, Coordinates, clampCoordinates } from "./Selection";
import { SheetKeys, isUnknownHotkey } from "./SheetKeys";

export type SheetUpdateCallback = (controller: SuperSheetController) => void;

export interface CellRegistration {
  ref: React.MutableRefObject<any>;
  path: string | string[];
  row: number;
  column: number;
  rowSpan?: number;
  colSpan?: number;
  handleKeyDown: (event: KeyboardEvent) => void;
}

export class SuperSheetController {
  selection: null | SheetSelection = null;
  edit: null | Coordinates = null;
  version: number = 0;
  cells: Map<number, Map<number, CellRegistration>> = new Map();
  updates: EventEmitter;
  containerRef: React.RefObject<HTMLDivElement> = React.createRef();
  processedEvents: WeakMap<Event, boolean> = new WeakMap();

  constructor(onChange: SheetUpdateCallback) {
    this.updates = new EventEmitter();
    this.updates.on("update", onChange);
  }

  isSelected(row: number, column: number) {
    if (!this.selection) return false;
    return (
      this.selection.anchor.row <= row &&
      this.selection.anchor.column <= column &&
      this.selection.focus.row >= row &&
      this.selection.focus.column >= column
    );
  }

  isEditing(row: number, column: number) {
    if (!this.edit) return false;
    return this.edit.row == row && this.edit.column == column;
  }

  isRegistrationSelected(registration: CellRegistration) {
    for (let selectedRegistration of this.getSelectedCellRegistrations()) {
      if (selectedRegistration.row == registration.row && selectedRegistration.column == registration.column) {
        return true;
      }
    }
    return false;
  }

  startEdit() {
    if (this.selection) {
      this.update({ edit: { row: this.selection.focus.row, column: this.selection.focus.column } });
    }
  }

  toggleEdit() {
    if (this.edit) {
      this.cancelEdit();
    } else {
      const registration = this.getSelectionFocusCellRegistration();
      if (!registration) {
        return this;
      }

      const coord = { row: registration.row, column: registration.column };
      this.moveSelectionTo(coord, coord).startEdit();
    }
  }

  cancelEdit() {
    this.update({ edit: null }).focusContainer();
  }

  clearSelection() {
    if (this.selection) {
      return this.update({ selection: null });
    }
    return this;
  }

  collapseSelection() {
    if (this.selection) {
      return this.update({ selection: { anchor: this.selection.focus, focus: this.selection.focus } });
    }
    return this;
  }

  moveSelectionTo(anchor: Coordinates, focus: Coordinates) {
    const { rowMin, rowMax, colMin, colMax } = this.dimensions();

    return this.focusContainer()
      .update({
        selection: {
          anchor: clampCoordinates(anchor, rowMin, rowMax, colMin, colMax),
          focus: clampCoordinates(focus, rowMin, rowMax, colMin, colMax)
        },
        edit: null
      })
      .scrollSelectedCellIntoView();
  }

  scrollSelectedCellIntoView() {
    const registration = this.getSelectionFocusCellRegistration();
    if (registration && registration.ref.current) {
      registration.ref.current.scrollIntoView({ inline: "center" });
    }
    return this;
  }

  moveSelectionDelta(rowDelta: number, columnDelta: number) {
    if (this.selection) {
      return this.moveSelectionTo(
        this.applyCellSpaceDelta(this.selection.anchor, rowDelta, columnDelta),
        this.applyCellSpaceDelta(this.selection.focus, rowDelta, columnDelta)
      );
    }
    return this;
  }

  // This implements rowspan and colspan aware cell movement. rowDelta and columnDelta are passed in as
  // the number of *unique* cells to move in a particular direction, so if you're moving through a rowspan
  // or colspan, that whole span should only count as one for the delta, instead of the actual length of the
  // span.
  applyCellSpaceDelta(coord: Coordinates, rowDelta: number, columnDelta: number) {
    let currentCell = this.getCellRegistration(coord.row, coord.column);
    let rowCursor = coord.row;
    const nextRow = rowDelta > 0 ? 1 : -1;
    let columnCursor = coord.column;
    const nextColumn = columnDelta > 0 ? 1 : -1;

    while (rowDelta != 0) {
      rowCursor += nextRow;
      let nextCell = this.getCellRegistration(rowCursor, coord.column);
      if (!nextCell || nextCell != currentCell) {
        rowDelta -= nextRow;
        currentCell = nextCell;
      }
    }

    while (columnDelta != 0) {
      columnCursor += nextColumn;
      let nextCell = this.getCellRegistration(rowCursor, columnCursor);
      if (!nextCell || nextCell != currentCell) {
        columnDelta -= nextColumn;
        currentCell = nextCell;
      }
    }

    const dimensions = this.dimensions();
    return clampCoordinates(
      { row: rowCursor, column: columnCursor },
      dimensions.rowMin,
      dimensions.rowMax,
      dimensions.colMin,
      dimensions.colMax
    );
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

  handleKeyDown = (event: React.KeyboardEvent) => {
    if (this.processedEvents.has(event.nativeEvent)) {
      return;
    }
    this.processedEvents.set(event.nativeEvent, true);

    const action = Object.entries(SheetKeys).find(([_name, action]) => {
      if (this.edit && !action.availableDuringEdit) {
        return false;
      }
      return action.check(event as any);
    });

    if (action) {
      action[1].action(this);
      event.preventDefault();
    }

    // If the key pressed is not a keyboard shortcut and is a letter, number, or puncutation mark
    // it's intended for the data in the cell. Set the value of the form to that data.
    if (!this.edit && this.selection && !isUnknownHotkey(event as any)) {
      const registration = this.getSelectionFocusCellRegistration();
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

  onCellBlur = () => {
    this.focusContainer();
  };

  focusContainer = () => {
    if (this.containerRef.current) {
      this.containerRef.current.focus();
    } else {
      // console.warn("trying to focus unmounted supersheet container");
    }
    return this;
  };

  registerCell(registration: CellRegistration, updateCallback: SheetUpdateCallback) {
    this.updates.on("update", updateCallback);

    // Register this cell for all the atomic cells it's responsible for across it's spans
    // For most cells, this is just the row and column in the registration, but if there's a
    // rowSpan or colSpan, then it will appear multiple times in the cell registration maps.
    const rows = range(registration.row, registration.row + (registration.rowSpan || 1));
    const columns = range(registration.column, registration.column + (registration.colSpan || 1));
    for (let row of rows) {
      let cellRow = this.cells.get(row);
      if (!cellRow) {
        cellRow = new Map<number, CellRegistration>();
        this.cells.set(row, cellRow);
      }

      for (let column of columns) {
        cellRow.set(column, registration);
      }
    }
  }

  unregisterCell(registration: CellRegistration, updateCallback: SheetUpdateCallback) {
    this.updates.off("update", updateCallback);
    const rows = range(registration.row, registration.row + (registration.rowSpan || 1));
    const columns = range(registration.column, registration.column + (registration.colSpan || 1));

    for (let row of rows) {
      let cellRow = this.cells.get(row);
      if (cellRow) {
        for (let column of columns) {
          cellRow.delete(column);
        }
      }
    }
  }

  getSelectionFocusCellRegistration() {
    if (!this.selection) return;
    return this.getCellRegistration(this.selection.anchor.row, this.selection.anchor.column);
  }

  *getSelectedCellRegistrations() {
    if (!this.selection) return;
    const registration = this.getCellRegistration(this.selection.focus.row, this.selection.focus.column);
    if (registration) {
      yield registration;
    }

    for (let row of range(this.selection.anchor.row, this.selection.focus.row)) {
      for (let column of range(this.selection.anchor.column, this.selection.focus.column)) {
        const registration = this.getCellRegistration(row, column);
        if (registration) {
          yield registration;
        }
      }
    }
  }

  getCellRegistration(row: number, column: number) {
    const cellRow = this.cells.get(row);
    if (cellRow) {
      return cellRow.get(column);
    }
  }

  update(update: Partial<Pick<SuperSheetController, "selection" | "edit">>) {
    Object.assign(this, update);
    this.version += 1;
    this.updates.emit("update", this);
    // console.debug("sheet change", this);
    return this;
  }
}
