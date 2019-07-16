import isHotkey from "is-hotkey";
import { SuperSheetController } from "./SuperSheetController";

export interface SheetKeyAction {
  availableDuringEdit: boolean;
  check: (event: KeyboardEvent) => boolean;
  action: (sheet: SuperSheetController) => void;
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
  tabRight: {
    availableDuringEdit: true,
    check: isHotkey("tab"),
    action: sheet => {
      sheet.moveSelectionDelta(0, 1);
    }
  },
  tabLeft: {
    availableDuringEdit: true,
    check: isHotkey("shift+tab"),
    action: sheet => {
      sheet.moveSelectionDelta(0, -1);
    }
  },
  toggleEditing: {
    availableDuringEdit: true,
    check: isHotkey("enter"),
    action: sheet => {
      if (sheet.selection) {
        sheet.toggleEdit(sheet.selection.focus.row, sheet.selection.focus.column);
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

const isMod = isHotkey("cmd");
const isControl = isHotkey("control");
const isOpt = isHotkey("opt");
export const isUnknownHotkey = (event: KeyboardEvent) => isMod(event) || isControl(event) || isOpt(event);
