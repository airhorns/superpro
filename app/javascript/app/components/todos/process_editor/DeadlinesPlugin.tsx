import React from "react";
import { Text } from "slate";
import { Plugin, RenderBlockProps } from "slate-react";
import { DropButton, Box, Text as TextComponent } from "grommet";
import isHotkey from "is-hotkey";

import { DividerHeading } from "app/components/common";
import { Deadline } from "app/components/common/FlurishIcons";
import { isAuthoringMode } from "./utils";
import { DatePicker, Row } from "flurishlib";
import { DateTime } from "luxon";

export const DeadlineContainer = (props: RenderBlockProps) => {
  const [showForm, setShowForm] = React.useState(false);
  const showDeadline = !isAuthoringMode(props.editor);
  const dueDate = props.node.data.get("dueDate");

  return (
    <DividerHeading>
      <Deadline />
      <div {...props.attributes}>{props.children}</div>
      {showDeadline && (
        <Row contentEditable={false}>
          <DropButton
            disabled={!showDeadline}
            open={showForm}
            onOpen={() => setShowForm(true)}
            onClose={() => setShowForm(false)}
            hoverIndicator
            dropContent={
              <Box pad="small">
                <DatePicker
                  value={dueDate}
                  onChange={value => {
                    props.editor.setNodeByKey(props.node.key, { data: { dueDate: value } } as any);
                    setShowForm(false);
                  }}
                />
              </Box>
            }
          >
            <Box width="small" align="center">
              <TextComponent weight="normal" color={dueDate ? undefined : "brand"}>
                {(dueDate && DateTime.fromISO(dueDate).toLocaleString(DateTime.DATE_FULL)) || "not set"}
              </TextComponent>
            </Box>
          </DropButton>
        </Row>
      )}
    </DividerHeading>
  );
};

export const DeadlinesPlugin = (_options?: {}): Plugin => {
  const isEnter = isHotkey("enter");

  return {
    renderBlock(props, editor, next) {
      switch (props.node.type) {
        case "deadline":
          return <DeadlineContainer {...props} />;
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
