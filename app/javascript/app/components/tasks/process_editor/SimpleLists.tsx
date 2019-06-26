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
    }
  };
};
