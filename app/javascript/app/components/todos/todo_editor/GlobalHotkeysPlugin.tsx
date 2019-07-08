import { Editor } from "slate";
import { Plugin } from "slate-react";
import Hotkeys from "slate-hotkeys";

export const GlobalHotkeysPlugin = (): Plugin => {
  const functions: { check: (event: Event, editor: Editor) => boolean; handler: Exclude<Plugin["onKeyDown"], undefined> }[] = [
    {
      check: Hotkeys.isUndo,
      handler: (_event, editor) => editor.undo()
    },
    {
      check: Hotkeys.isRedo,
      handler: (_event, editor) => editor.redo()
    }
  ];

  return {
    onKeyDown(event, editor, next) {
      const shortcut = functions.find(shortcut => shortcut.check(event, editor));
      if (shortcut) {
        console.debug("found shortcut");
        return shortcut.handler(event, editor, next);
      } else {
        return next();
      }
    }
  };
};
