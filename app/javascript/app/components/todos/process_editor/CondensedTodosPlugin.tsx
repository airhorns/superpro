import { Plugin } from "slate-react";
import { Block, Document, Range } from "slate";
import { List } from "immutable";
import { DateTime } from "luxon";

export const CondensedTodosPlugin = (): Plugin => {
  const RenderRangeCache = new WeakMap<Document, Range>();
  const startOfWeek = DateTime.local().startOf("week");

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

      const renderRange = editor.query("condensedRenderRange");
      if ((editor.value.document as any).isInRange(props.node.key, renderRange)) {
        return next();
      } else {
        return null;
      }
    },
    commands: {
      toggleShowOnlyCondensedTodos(editor) {
        (editor as any).setData({ showOnlyCondensedTodos: !editor.value.data.get("showOnlyCondensedTodos") }).rerenderAll();
        return editor;
      }
    },
    queries: {
      condensedRenderRange: editor => {
        const cached = RenderRangeCache.get(editor.value.document);
        if (cached) {
          return cached;
        }

        const deadlines = editor.value.document.filterDescendants(node => node.object == "block" && node.type == "deadline") as List<Block>;
        let range = Range.create({}).moveToRangeOfNode(editor.value.document);

        let firstFutureIndex = deadlines.findIndex(deadline => {
          if (deadline) {
            const dueDate = deadline.data.get("dueDate");
            if (dueDate) {
              return DateTime.fromISO(dueDate).startOf("week") > startOfWeek;
            }
          }
          return false;
        });

        if (firstFutureIndex >= 0) {
          range = range.moveEndToEndOfNode(deadlines.get(firstFutureIndex));
        }

        return range;
      },
      unrenderedDeadlineCount: editor => {
        if (!editor.value.data.get("showOnlyCondensedTodos")) {
          return 0;
        }
        const renderRange: Range = editor.query("condensedRenderRange");
        return editor.value.document.filterDescendants(
          node => node.object == "block" && node.type == "deadline" && !(editor.value.document as any).isInRange(node.key, renderRange)
        ).size;
      }
    }
  };
};
