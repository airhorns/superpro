import shortid from "shortid";
import { Plugin } from "slate-react";

// A hacky way to rerender the whole editor on demand when something important changes elsewhere
// is to re-annotate the whole editor with an invisible annotation.
export const RerenderPlugin = (): Plugin => {
  return {
    commands: {
      rerenderAll(editor: any) {
        editor.withoutSaving(() => {
          editor.value.annotations.forEach((ann: any) => {
            if (ann.type === "refresh-hack") {
              editor.removeAnnotation(ann);
            }
          });

          editor.moveToRangeOfDocument();
          editor.addAnnotation({
            key: shortid.generate(),
            type: "refresh-hack",
            anchor: editor.value.selection.anchor,
            focus: editor.value.selection.focus
          });
          editor.moveToStartOfDocument();
        });

        return editor;
      }
    }
  };
};
