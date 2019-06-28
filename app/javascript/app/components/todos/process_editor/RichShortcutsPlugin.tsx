import { Plugin, EventHook } from "slate-react";
import isHotkey from "is-hotkey";

const isBackspace = isHotkey("backspace");
const isSpace = isHotkey("space");

export const RichShortcutsPlugin = (_options?: {}): Plugin => {
  const getType = (chars: string) => {
    switch (chars) {
      case "*":
      case "-":
        return "list-item";
      case "___":
        return "deadline";
      case "+":
      case "[]":
        return "check-list-item";
      case ">":
        return "block-quote";
      case "#":
        return "heading-one";
      case "##":
        return "heading-two";
      default:
        return null;
    }
  };

  const onSpace: EventHook = (event, editor, next) => {
    const { value } = editor;
    const { selection } = value;
    if (selection.isExpanded) return next();

    const { startBlock } = value;
    const { start } = selection;
    const chars = startBlock.text.slice(0, start.offset).replace(/\s*/g, "");
    const type = getType(chars);
    if (!type) return next();
    if (type === "list-item" && startBlock.type === "list-item") return next();
    event.preventDefault();

    editor.setBlocks(type);

    if (type === "list-item") {
      editor.wrapBlock("bulleted-list");
    }

    editor.moveFocusToStartOfNode(startBlock).delete();
  };

  const onBackspace: EventHook = (event, editor, next) => {
    const { value } = editor;
    const { selection } = value;
    if (selection.isExpanded) return next();
    if (selection.start.offset !== 0) return next();

    const { startBlock } = value;
    if (startBlock.type === "paragraph") return next();

    event.preventDefault();
    editor.setBlocks("paragraph");

    if (startBlock.type === "list-item") {
      editor.unwrapBlock("bulleted-list");
    }
  };

  return {
    onKeyDown(event, editor, next) {
      if (isSpace(event as any)) {
        return onSpace(event, editor, next);
      }

      if (isBackspace(event as any)) {
        return onBackspace(event, editor, next);
      }

      return next();
    }
  };
};
