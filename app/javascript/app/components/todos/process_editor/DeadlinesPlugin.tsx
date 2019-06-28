import React from "react";
import { Text } from "slate";
import { Plugin } from "slate-react";
import { DividerHeading } from "app/components/common";
import isHotkey from "is-hotkey";
import { Deadline } from "app/components/common/FlurishIcons";

export const DeadlinesPlugin = (_options?: {}): Plugin => {
  const isEnter = isHotkey("enter");

  return {
    renderBlock(props, editor, next) {
      switch (props.node.type) {
        case "deadline":
          return (
            <DividerHeading>
              <Deadline />
              <div {...props.attributes}>{props.children}</div>
            </DividerHeading>
          );
        default:
          return next();
      }
    },
    onKeyDown(event, editor, next) {
      if (isEnter(event as any) && editor.value.startBlock.type === "deadline") {
        editor.splitBlock().setBlocks("paragraph");
      } else {
        return next();
      }
    },
    commands: {
      addDeadline: editor => {
        const deadlineCount = editor.value.document.getBlocksByType("deadline").size;
        return editor.moveToEndOfBlock().insertBlock({
          type: "deadline",
          nodes: [Text.create({ text: `Deadline ${deadlineCount + 1}` })],
          data: {
            dueDate: null
          }
        } as any);
      }
    }
  };
};
