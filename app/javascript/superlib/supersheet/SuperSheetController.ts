import React from "react";
import EventEmitter from "eventemitter3";
import { SheetSelection, Coordinates, moveCoordinates, clampCoordinates } from "./Selection";
import { SheetKeys, isUnknownHotkey } from "./SheetKeys";

export type SheetUpdateCallback = (controller: SuperSheetController) => void;

export interface CellRegistration {
  ref: React.MutableRefObject<any>;
  path: string | string[];
  row: number;
  column: number;
  handleKeyDown: (event: KeyboardEvent) => void;
}

export class SuperSheetController {
  selection: null | SheetSelection = null;
  edit: null | Coordinates = null;
  version: number = 0;
  cells: Map<number, Map<number, CellRegistration>> = new Map();
  updates: EventEmitter;
  containerRef: React.RefObject<HTMLDivElement> = React.createRef();

  constructor(onChange: SheetUpdateCallback) {
    this.updates = new EventEmitter();
    this.updates.on("update", onChange);
  }

  isSelected(row: number, column: number) {
    if (!this.selection) return false;
    return (
      this.selection.start.row <= row &&
      this.selection.start.column <= column &&
      this.selection.end.row >= row &&
      this.selection.end.column >= column
    );
  }

  isEditing(row: number, column: number) {
    if (!this.edit) return false;
    return this.edit.row == row && this.edit.column == column;
  }

  startEdit() {
    if (this.selection) {
      this.update({ edit: { row: this.selection.start.row, column: this.selection.start.column } });
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
    if (this.selection) {
      return this.update({ selection: null });
    }
    return this;
  }

  collapseSelection() {
    if (this.selection) {
      return this.update({ selection: { start: this.selection.start, end: this.selection.start } });
    }
    return this;
  }

  moveSelectionTo(start: Coordinates, end: Coordinates) {
    const { rowMin, rowMax, colMin, colMax } = this.dimensions();

    return this.focusContainer()
      .update({
        selection: {
          start: clampCoordinates(start, rowMin, rowMax, colMin, colMax),
          end: clampCoordinates(end, rowMin, rowMax, colMin, colMax)
        },
        edit: null
      })
      .scrollSelectedCellIntoView();
  }

  scrollSelectedCellIntoView() {
    const registration = this.getSelectedCellRegistration();
    if (registration && registration.ref.current) {
      registration.ref.current.scrollIntoView({ inline: "center" });
    }
    return this;
  }

  moveSelectionDelta(rowDelta: number, columnDelta: number) {
    if (this.selection) {
      return this.moveSelectionTo(
        moveCoordinates(this.selection.start, rowDelta, columnDelta),
        moveCoordinates(this.selection.end, rowDelta, columnDelta)
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

  handleKeyDown = (event: React.KeyboardEvent) => {
    const action = Object.entries(SheetKeys).find(([_name, action]) => {
      if (this.edit && !action.availableDuringEdit) {
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
    if (!this.edit && this.selection && !isUnknownHotkey(event as any)) {
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
    let cellRow = this.cells.get(registration.row);
    if (!cellRow) {
      cellRow = new Map<number, CellRegistration>();
      this.cells.set(registration.row, cellRow);
    }
    cellRow.set(registration.column, registration);
  }

  unregisterCell(registration: CellRegistration, updateCallback: SheetUpdateCallback) {
    this.updates.off("update", updateCallback);
    let cellRow = this.cells.get(registration.row);
    if (cellRow) {
      cellRow.delete(registration.column);
    }
  }

  getSelectedCellRegistration() {
    if (!this.selection) return;
    const cellRow = this.cells.get(this.selection.start.row);
    if (cellRow) {
      return cellRow.get(this.selection.start.column);
    }
  }

  update(update: Partial<Pick<SuperSheetController, "selection" | "edit">>) {
    Object.assign(this, update);
    this.version += 1;
    this.updates.emit("update", this);
    return this;
  }
}
