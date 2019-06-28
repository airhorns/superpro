import React from "react";
import { Plugin } from "slate-react";
import { Value } from "slate";
import isHotkey from "is-hotkey";
import { Heading } from "grommet";
import styled from "styled-components";
const isEnter = isHotkey("enter");

const NiceHeading = styled(Heading)`
  ${props => `
  margin-top: ${props.theme.global.edgeSize["medium"]};
  margin-bottom: ${props.theme.global.edgeSize["small"]}`};
`;

const NiceBlockQuote = styled.div`
  ${props => `
  padding-top: ${props.theme.global.edgeSize["small"]};
  padding-bottom: ${props.theme.global.edgeSize["small"]};
  padding-left: ${props.theme.global.edgeSize["medium"]};
  margin-top: ${props.theme.global.edgeSize["xsmall"]};
  border-left: 5px solid ${props.theme.global.colors["light-3"]};
  & + & {
    padding-top: 0px;
    margin-top: 0px;
  }
`}
`;

export const BasicFormattingPlugin = (): Plugin => {
  return {
    renderBlock(props, _editor, next) {
      switch (props.node.type) {
        case "block-quote":
          return <NiceBlockQuote {...props.attributes}>{props.children}</NiceBlockQuote>;
        case "heading-one":
          return (
            <NiceHeading level="2" {...props.attributes}>
              {props.children}
            </NiceHeading>
          );
        case "heading-two":
          return (
            <NiceHeading level="3" {...props.attributes}>
              {props.children}
            </NiceHeading>
          );
        default:
          return next();
      }
    },
    renderInline(props, _editor, next) {
      switch (props.node.type) {
        case "link":
          return (
            <a {...props.attributes} href={props.node.data.get("url")}>
              {props.children}
            </a>
          );
        default:
          return next();
      }
    },
    onKeyDown(event, editor, next) {
      const { value } = editor;

      if (isEnter(event as any)) {
        if (value.startBlock.type.startsWith("heading")) {
          editor.splitBlock().setBlocks("paragraph");
          return;
        }

        if (value.startBlock.type == "block-quote" && value.startText.text.length == 0) {
          editor.setBlocks("paragraph");
          return;
        }
      }

      next();
    },
    commands: {
      wrapLink(editor, url) {
        return editor.wrapInline({ type: "link", data: { url } });
      },
      unwrapLink(editor) {
        return editor.unwrapInline("link");
      }
    },
    queries: {
      isLinkActive(editor, value: Value) {
        const { inlines } = value;
        const active = inlines.some(node => !!(node && node.type === "link"));
        return active;
      }
    }
  };
};
