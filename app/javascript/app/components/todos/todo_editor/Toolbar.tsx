import React from "react";
import { Row } from "superlib";
import { Button, ButtonProps, Box, Text } from "grommet";
import { Editor } from "slate-react";
import { IconProps } from "grommet-icons";

const DEFAULT_NODE = "paragraph";

export const ToolbarButton = (props: { active: boolean; icon: React.ComponentType<IconProps>; onClick: ButtonProps["onClick"] }) => (
  <Button active={props.active} onClick={props.onClick} plain focusIndicator={false}>
    <Box pad="xsmall" background={props.active ? "light-5" : undefined}>
      {React.createElement(props.icon, { color: props.active ? "brand" : undefined })}
    </Box>
  </Button>
);

export const Toolbar = (props: { children: React.ReactNode }) => {
  return (
    <Row pad="xsmall" gap="xsmall" margin={{ bottom: "small" }} round="small" background="light-1">
      {props.children}
    </Row>
  );
};

export const ToolbarDivider = () => (
  <Box pad="xsmall">
    <Text color="light-6">|</Text>
  </Box>
);

export class ToggleMarkToolbarButton extends React.Component<{ type: string; icon: React.ComponentType; editor: Editor }> {
  hasMark() {
    return this.props.editor.value.activeMarks.some(mark => !!(mark && mark.type === this.props.type));
  }

  onClick = (event: React.SyntheticEvent<HTMLButtonElement>) => {
    event.preventDefault();
    this.props.editor.toggleMark(this.props.type);
  };

  render() {
    return <ToolbarButton active={this.hasMark()} icon={this.props.icon} onClick={this.onClick} />;
  }
}

export class ToggleBlockToolbarButton extends React.Component<{
  type: string;
  icon: React.ComponentType;
  editor: Editor;
  newBlockData?: any;
}> {
  hasBlock(type: string) {
    return this.props.editor.value.blocks.some(node => !!(node && node.type === type));
  }

  onClick = (event: React.SyntheticEvent<HTMLButtonElement>) => {
    event.preventDefault();

    // Handle everything but list buttons.
    if (this.props.type !== "bulleted-list" && this.props.type !== "numbered-list") {
      const isActive = this.hasBlock(this.props.type);
      const isList = this.hasBlock("list-item");
      const newBlockProperties = isActive ? DEFAULT_NODE : { type: this.props.type, data: this.props.newBlockData };

      if (isList) {
        this.props.editor
          .setBlocks(newBlockProperties)
          .unwrapBlock("bulleted-list")
          .unwrapBlock("numbered-list");
      } else {
        this.props.editor.setBlocks(newBlockProperties);
      }
    } else {
      // Handle the extra wrapping required for list buttons.
      const isList = this.hasBlock("list-item");
      const isType = this.props.editor.value.blocks.some(block => {
        return !!(
          block &&
          this.props.editor.value.document.getClosest(block.key, parent => parent.object == "block" && parent.type === this.props.type)
        );
      });

      if (isList && isType) {
        this.props.editor
          .setBlocks(DEFAULT_NODE)
          .unwrapBlock("bulleted-list")
          .unwrapBlock("numbered-list");
      } else if (isList) {
        this.props.editor.unwrapBlock(this.props.type === "bulleted-list" ? "numbered-list" : "bulleted-list").wrapBlock(this.props.type);
      } else {
        this.props.editor.setBlocks("list-item").wrapBlock(this.props.type);
      }
    }
  };

  render() {
    let isActive = this.hasBlock(this.props.type);

    if (["numbered-list", "bulleted-list"].includes(this.props.type)) {
      const {
        value: { document, blocks }
      } = this.props.editor;

      if (blocks.size > 0) {
        const parent = document.getParent(blocks.first().key);
        isActive = !!(this.hasBlock("list-item") && parent && parent.object == "block" && parent.type === this.props.type);
      }
    }

    return <ToolbarButton active={isActive} icon={this.props.icon} onClick={this.onClick} />;
  }
}
