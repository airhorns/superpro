import { Plugin } from "slate-react";

export const HideVerboseContentPlugin = (): Plugin => {
  let showVerboseContent = true;

  return {
    renderBlock(props, editor, next) {
      if (showVerboseContent) {
        return next();
      }

      switch (props.node.type) {
        case "block-quote":
        case "paragraph":
          return null;
      }

      return next();
    },
    commands: {
      showVerboseContent: editor => {
        showVerboseContent = true;
        editor.deselect();
        return editor;
      },
      hideVerboseContent: editor => {
        showVerboseContent = false;
        editor.deselect();
        return editor;
      }
    }
  };
};
