import React from "react";
import { Plugin, RenderBlockProps } from "slate-react";
import { Box, Image, Anchor } from "grommet";
import { Row, assert } from "superlib";
import FileIcon, { defaultStyles } from "react-file-icon";

export const FileAttachmentBox = (props: RenderBlockProps) => {
  const extension = assert(props.node.data.get("filename"))
    .split(".")
    .pop();
  const iconStyle = defaultStyles[extension] || {};
  return (
    <Row justify="center" border={{ side: "all", color: props.isSelected ? "focus" : "light-1" }} pad="small" gap="small">
      <Box>
        <FileIcon size={48} extension={extension} {...iconStyle} />
      </Box>
      <Anchor href={props.node.data.get("url")}>{props.node.data.get("filename")}</Anchor>
    </Row>
  );
};

export const ImageBox = (props: RenderBlockProps) => {
  return (
    <Row
      justify="center"
      border={props.isSelected ? { side: "all", color: "focus" } : undefined}
      onClick={() => props.editor.moveToStartOfNode(props.node)}
    >
      <Image {...props.attributes} src={props.node.data.get("url")} fit="contain" style={{ maxHeight: "336px" }} />
    </Row>
  );
};

export const RenderAttachmentsPlugin = (_options = {}): Plugin => {
  return {
    renderBlock(props, _editor, next) {
      switch (props.node.type) {
        case "image":
          return <ImageBox {...props} />;
        case "file-attachment":
          return <FileAttachmentBox {...props} />;
        default:
          return next();
      }
    }
  };
};
