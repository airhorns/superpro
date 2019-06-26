import React from "react";
import { Plugin } from "slate-react";
import { Value } from "slate";

export const BasicFormattingPlugin = (): Plugin => {
  return {
    renderBlock(props, _editor, next) {
      switch (props.node.type) {
        case "block-quote":
          return <blockquote {...props.attributes}>{props.children}</blockquote>;
        case "heading-one":
          return <h1 {...props.attributes}>{props.children}</h1>;
        case "heading-two":
          return <h2 {...props.attributes}>{props.children}</h2>;
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
