import isHotkey from "is-hotkey";
import { Sheet } from "./Sheet";

export interface SheetKeyAction {
  availableDuringEdit: boolean;
  check: (event: KeyboardEvent) => boolean;
  action: (sheet: Sheet) => void;
}

export const SheetKeys: { [key: string]: SheetKeyAction } = {
  moveRight: {
    availableDuringEdit: false,
    check: isHotkey("right"),
    action: sheet => {
      sheet.moveSelectionDelta(0, 1);
    }
  },
  moveLeft: {
    availableDuringEdit: false,
    check: isHotkey("left"),
    action: sheet => {
      sheet.moveSelectionDelta(0, -1);
    }
  },
  moveUp: {
    availableDuringEdit: false,
    check: isHotkey("up"),
    action: sheet => {
      sheet.moveSelectionDelta(-1, 0);
    }
  },
  moveDown: {
    availableDuringEdit: false,
    check: isHotkey("down"),
    action: sheet => {
      sheet.moveSelectionDelta(1, 0);
    }
  },
  toggleEditing: {
    availableDuringEdit: true,
    check: isHotkey("enter"),
    action: sheet => {
      if (sheet.state.selection) {
        sheet.toggleEdit(sheet.state.selection.start.row, sheet.state.selection.start.column);
      }
    }
  },
  cancelEditing: {
    availableDuringEdit: true,
    check: isHotkey("escape"),
    action: sheet => {
      sheet.cancelEdit();
    }
  }
};
