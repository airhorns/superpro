import React from "react";
import { Block, Data } from "slate";
import { Plugin, RenderBlockProps } from "slate-react";
import { Box, Heading } from "grommet";

export const StageContainer = (props: RenderBlockProps) => (
  <Box margin={{ bottom: "small" }}>
    <Box pad="xsmall">
      <Heading level="5" contentEditable={false}>
        {props.node.data.get("title")}
      </Heading>
    </Box>
    <Box pad="small" background="white">
      {props.children}
    </Box>
  </Box>
);

export const StagesPlugin = (_options?: {}): Plugin => {
  return {
    renderBlock(props, editor, next) {
      switch (props.node.type) {
        case "stage":
          return <StageContainer {...props} />;
        default:
          return next();
      }
    },
    commands: {
      addStage: editor => {
        return editor.insertNodeByKey(
          editor.value.document.key,
          editor.value.document.nodes.size,
          Block.create({
            type: "stage",
            nodes: Block.createList(["paragraph"]),
            data: Data.create({
              title: `Stage ${editor.value.document.nodes.size + 1}`
            })
          })
        );
      }
    }
  };
};
