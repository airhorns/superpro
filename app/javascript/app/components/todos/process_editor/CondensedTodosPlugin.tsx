import { Plugin } from "slate-react";

export const CondensedTodosPlugin = (): Plugin => {
  return {
    renderBlock(props, editor, next) {
      if (!editor.value.data.get("showOnlyCondensedTodos")) {
        return next();
      }

      switch (props.node.type) {
        case "block-quote":
        case "paragraph":
          return null;
      }

      return next();
    }
  };
};
