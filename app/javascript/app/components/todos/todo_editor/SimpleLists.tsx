import React from "react";
import { Plugin } from "slate-react";

export const SimpleListsPlugin = (): Plugin => {
  return {
    renderBlock(props, _editor, next) {
      switch (props.node.type) {
        case "bulleted-list":
          return <ul {...props.attributes}>{props.children}</ul>;
        case "numbered-list":
          return <ol {...props.attributes}>{props.children}</ol>;
        case "list-item":
          return <li {...props.attributes}>{props.children}</li>;
        default:
          return next();
      }
    },
    onKeyDown(event, editor, next) {
      const { value } = editor;
      const key = (event as any).key;

      if (key === "Enter" && value.startBlock.type === "list-item") {
        // On starting a new line with the enter key, add a new block of the same type that isn't checked below by splitting the current block
        if (value.startText.text.length > 0) {
          editor.splitBlock();
        } else {
          // Otherwise, convert this block back to a paragraph and unwrap it
          editor
            .setBlocks("paragraph")
            .unwrapBlock("bulleted-list")
            .unwrapBlock("numbered-list");
        }
        return;
      }

      next();
    }
  };
};
